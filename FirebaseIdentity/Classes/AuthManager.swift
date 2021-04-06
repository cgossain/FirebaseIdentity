//
//  AuthManager.swift
//
//  Copyright (c) 2019-2021 Christian Gossain
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import FirebaseAuth
import ProcedureKit

extension AuthManager {
    /// Posted on the main queue when the authentication state changes.
    public static let authenticationStateChangedNotification = Notification.Name("com.firebaseidentity.authmanager.authenticationstatechangednotification")
}

extension AuthManager {
    /// The block that is invoked when an authentication related event completes. The parameter
    /// passed to the block is an `AuthManager.Result` object that may indicate that a
    /// further user action is required.
    public typealias AuthResultHandler = (Result<AuthDataResult, AuthenticationError>) -> Void

    /// The block that is invoked when a provider unlink event completes.
    public typealias AuthUnlinkHandler = (Result<User, Error>) -> Void

    /// The block that is invoked when a profile change event completes.
    public typealias ProfileChangeHandler = (Result<User, ProfileChangeError>) -> Void

    /// The block that is optionally invoked when the `reauthenticate()` method completes.
    public typealias ReauthenticationHandler = (AuthenticationError?) -> Void

    /// The block that is optionally invoked when the `requestReauthentication()` method completes.
    public typealias ReauthenticationRequestHandler = (AuthManager.ReauthenticationStatus) -> Void
}

/// An object that manages all Firebase authentication and user related events.
public class AuthManager {
    public enum State {
        case notDetermined
        case notAuthenticated
        case authenticated
    }
    
    public enum ReauthenticationStatus {
        case success
        case failure(ProfileChangeError)
        case unnecessary
    }
    
    /// The shared instance.
    public static let shared = AuthManager()
    
    /// The object that will handle reauthentication callbacks.
    public weak var reauthenticator: AuthManagerReauthenticating?
    
    /// The authentication state of the receiver.
    public private(set) var authenticationState = State.notDetermined
    
    /// The currently authenticated user, or nil if user is not authenticated.
    public private(set) var authenticatedUser: User?
    
    /// Indicates if the user account is currently in the process of being deleted.
    public private(set) var isDeletingUserAccount = false
    
    /// The list of identity providers associated with the currently authenticated user.
    ///
    /// - note: The providers are returned in sorted by the priority order specified in `providerReauthenticationPriority`.
    public var linkedProviders: [IdentityProviderUserInfo] {
        let providers: [IdentityProviderUserInfo] = authenticatedUser?.providerData.compactMap({
            guard let providerID = IdentityProviderID(rawValue: $0.providerID) else {
                return nil
            }
            return IdentityProviderUserInfo(providerID: providerID, email: $0.email, displayName: $0.displayName)
        }) ?? []
        
        // sort according to the priority order
        // https://stackoverflow.com/a/51683055/485352
        return providers.sorted {
            guard let lhs = linkedProviderPriority.firstIndex(of: $0.providerID) else { return false }
            guard let rhs = linkedProviderPriority.firstIndex(of: $1.providerID) else { return true }
            return lhs < rhs
        }
    }
    
    /// The order of priority that identity providers should listed in the `linkedProviders` array.
    ///
    /// This array is used for things like reauthentication when needed.
    ///
    /// - Note: Defaults to `email` as the first provider.
    public var linkedProviderPriority: [IdentityProviderID] = IdentityProviderID.allCases.sorted { (lhs, rhs) -> Bool in return lhs == .email }
    
    /// The last authentication date of the currently signed in user (includes sign-ins and reauthentications).
    public var lastAuthenticationDate: Date? {
        var dates: [Date] = []
        
        if let lastSignInDate = authenticatedUser?.metadata.lastSignInDate {
            dates.append(lastSignInDate)
        }
        
        if let lastReauthenticationDate = lastReauthenticationDate {
            dates.append(lastReauthenticationDate)
        }
        
        let descending = dates.sorted(by: >)
        return descending.first
    }
    
    
    // MARK: - Private Properties
    /// Indicates if reauthentication will be required to perform a profile change. You can use this property to preemptively reauthenticate before performing a profile change.
    private var needsReauthenticationForProfileChanges: Bool {
        guard let lastAuthenticationDate = lastAuthenticationDate else {
            return false
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute], from: lastAuthenticationDate, to: Date())
        
        guard let minute = components.minute else {
            return false
        }
        
        return minute >= 5
    }
    
    /// The last reauthentication date of the currently signed in user.
    private var lastReauthenticationDate: Date? {
        get {
            let defaults = UserDefaults.standard
            let d = defaults.value(forKey: "com.firebaseidentity.authmanager.lastreauthenticationdate") as? Date
            return d
        }
        set {
            let defaults = UserDefaults.standard
            defaults.set(newValue, forKey: "com.firebaseidentity.authmanager.lastreauthenticationdate")
        }
    }
    
    /// Returns the linked email identity provider user info, otherwise returns nil if there is no linked email identity provider.
    private var linkedEmailProviderUserInfo: IdentityProviderUserInfo? { return self.linkedProviders.filter({ $0.providerID == .email }).first }
    
    /// An internal procedure queue for authentication procedures (i.e. sign-up, sign-in, reauthentication, etc).
    ///
    /// The primary purpose for using procedure for authentication is that it provides a way to maintain a strong reference to the
    /// identity provider while the authentication action is in progress. An additional benefit is that a serial queue allows us
    /// to run tasks in the same order they are submitted.
    private var authenticationQueue: ProcedureQueue = {
        let queue = ProcedureQueue()
        queue.name = "com.firebaseIdentity.authManager.authenticationQueue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    /// Seprate internal queue for running the `DeleteAccountOperation`.
    ///
    /// This operation uses sub-operations that use the `authenticationQueue`. Since this is a serial queue, these operations would be
    /// blocked until the `DeleteAccountOperation` and so on. In other words, all execution would be paused. A separate serial queue
    /// solves this issue.
    private var accountDeletionQueue: ProcedureQueue = {
        let queue = ProcedureQueue()
        queue.name = "com.firebaseIdentity.authManager.accountDeletionQueue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    
    // MARK: - Lifecycle
    /// Configures the shared AuthManager instance.
    ///
    /// This method should be called shortly after the app is launched after the Firebase services have been configured (i.e. `FirebaseApp.configure()`).
    public static func configure() {
        AuthManager.shared.start()
    }
}

extension AuthManager {
    /// Enqueues a sign up operation.
    public func signUp<P: IdentityProvider>(with provider: P, completion: @escaping AuthResultHandler) {
        authenticationQueue.addOperation(AuthOperation(provider: provider, authenticationType: .signUp) { (result, error) in
            guard let error = error else {
                completion(.success(result!))
                return
            }
            
            let context = AuthenticationError.Context(providerID: provider.providerID, authenticationType: .signUp)
            self.handleAuthProcedureFirebaseError(error, context: context, provider: provider, completion: completion)
        })
    }
    
    /// Enqueues a sign in operation.
    public func signIn<P: IdentityProvider>(with provider: P, completion: @escaping AuthResultHandler) {
        authenticationQueue.addOperation(AuthOperation(provider: provider, authenticationType: .signIn) { (result, error) in
            guard let error = error else {
                completion(.success(result!))
                return
            }
            
            let context = AuthenticationError.Context(providerID: provider.providerID, authenticationType: .signIn)
            self.handleAuthProcedureFirebaseError(error, context: context, provider: provider, completion: completion)
        })
    }
    
    /// Enqueues a account linking operation.
    public func linkWith<P: IdentityProvider>(with provider: P, completion: @escaping AuthResultHandler) {
        authenticationQueue.addOperation(AuthOperation(provider: provider, authenticationType: .linkProvider) { (result, error) in
            guard let error = error else {
                completion(.success(result!))
                return
            }
            
            let context = AuthenticationError.Context(providerID: provider.providerID, authenticationType: .linkProvider)
            self.handleAuthProcedureFirebaseError(error, context: context, provider: provider, completion: completion)
        })
    }
    
    /// Enqueues a reauthentication operation.
    public func reauthenticate<P: IdentityProvider>(with provider: P, for challenge: ProfileChangeReauthenticationChallenge, completion: ReauthenticationHandler? = nil) {
        self.reauthenticate(with: provider) { (result) in
            switch result {
            case .success(_):
                self.lastReauthenticationDate = Date()
                completion?(nil)
                
                // retry the profile change attempt that failed using the error context
                switch challenge.context.profileChangeType {
                case .requestReauthentication:
                    challenge.completion(.success(challenge.context.authenticatedUser))
                    
                case .updateEmail(let email):
                    self.updateEmail(to: email, completion: challenge.completion)
                    
                case .updatePassword(let password):
                    self.updatePassword(to: password, completion: challenge.completion)
                    
                case .deleteAccount:
                    self.deleteAccount(with: challenge.completion)
                    
                default:
                    break
                }
                
            case .failure(let error):
                completion?(error)
                
                // notify the completion handler associated with the challenge about the failure
                challenge.completion(.failure(.other(error.localizedDescription, challenge.context)))
            }
        }
    }
    
    /// Cancels reauthenticatoin.
    public func cancelReauthentication(for challenge: ProfileChangeReauthenticationChallenge) {
        challenge.completion(.failure(.cancelledByUser(challenge.context)))
    }
    
    /// Requests a reauthentication to begin.
    public func requestReauthentication(passwordForReauthentication: String? = nil, completion: @escaping ReauthenticationRequestHandler) {
        guard let authenticatedUser = authenticatedUser else {
            return
        }
        
        if !needsReauthenticationForProfileChanges {
            completion(.unnecessary)
            return
        }
        
        let context = ProfileChangeError.Context(authenticatedUser: authenticatedUser, profileChangeType: .requestReauthentication)
        if let passwordForReauthentication = passwordForReauthentication,
            let linkedEmailProviderUserInfo = linkedEmailProviderUserInfo,
            let email = linkedEmailProviderUserInfo.email {
            let challenge = ProfileChangeReauthenticationChallenge(context: context) { (result) in
                switch result {
                case .success(_):
                    completion(.success)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            
            // attempt silently reauthenticating via the linked email provider
            // using the provided password
            let provider = EmailIdentityProvider(email: email, password: passwordForReauthentication)
            reauthenticate(with: provider, for: challenge)
        }
        else if let reauthenticator = reauthenticator {
            // 1. notify the delegate that we need to reauthenticate
            // 2. after a successful reauthentication, we need to continue the profile change and eventually call the completion handler
            let challenge = ProfileChangeReauthenticationChallenge(context: context) { (result) in
                switch result {
                case .success(_):
                    completion(.success)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            reauthenticator.authManager(self, reauthenticateUsing: self.linkedProviders, challenge: challenge)
        }
        else {
            completion(.failure(.missingReauthenticationMethod(context)))
        }
    }
    
    /// Signs out the current user.
    public func signOut() {
        try? Auth.auth().signOut()
    }
}

extension AuthManager {
    /// Updates the display name of the currently signed in user.
    public func updateDisplayName(to newDisplayName: String, passwordForReauthentication: String? = nil, completion: @escaping ProfileChangeHandler) {
        guard let authenticatedUser = authenticatedUser else {
            return
        }
        
        let profileChangeRequest = authenticatedUser.createProfileChangeRequest()
        profileChangeRequest.displayName = newDisplayName
        profileChangeRequest.commitChanges { (error) in
            guard let error = error else {
                // ensure the user is refreshed
                authenticatedUser.reload() { (_) in
                    completion(.success(authenticatedUser))
                }
                return
            }

            let context = ProfileChangeError.Context(authenticatedUser: authenticatedUser, profileChangeType: .updateDisplayName(newDisplayName))
            self.handleProfileChangeFirebaseError(error, context: context, passwordForReauthentication: passwordForReauthentication, completion: completion)
        }
    }
    
    /// Updates the email address of the currently signed in user.
    ///
    /// - parameters:
    ///     - newEmail: The new email address for the user.
    ///     - passwordForReauthentication: If provided, this password will be silently used to reauthenticate using the `email` provider (if available) and if the `requiresRecentLogin` Firebase error is triggered. Otherwise, reauthentication occurs via the `reauthenticator` object.
    public func updateEmail(to newEmail: String, passwordForReauthentication: String? = nil, completion: @escaping ProfileChangeHandler) {
        guard let authenticatedUser = authenticatedUser else {
            return
        }

        authenticatedUser.updateEmail(to: newEmail) { (error) in
            guard let error = error else {
                // ensure the user is refreshed
                authenticatedUser.reload() { (_) in
                    completion(.success(authenticatedUser))
                }
                return
            }

            let context = ProfileChangeError.Context(authenticatedUser: authenticatedUser, profileChangeType: .updateEmail(newEmail))
            self.handleProfileChangeFirebaseError(error, context: context, passwordForReauthentication: passwordForReauthentication, completion: completion)
        }
    }
    
    /// Updates (or sets) the password of the currently signed in user.
    ///
    /// - parameters:
    ///     - newPassword: The new password for the user.
    ///     - passwordForReauthentication: If provided, this password will be silently used to reauthenticate using the `email` provider (if available) and if the `requiresRecentLogin` Firebase error is triggered. Otherwise, reauthentication occurs via the `reauthenticator` object.
    public func updatePassword(to newPassword: String, passwordForReauthentication: String? = nil, completion: @escaping ProfileChangeHandler) {
        guard let authenticatedUser = authenticatedUser else {
            return
        }
        
        authenticatedUser.updatePassword(to: newPassword) { (error) in
            guard let error = error else {
                // ensure the user is refreshed
                authenticatedUser.reload() { (_) in
                    completion(.success(authenticatedUser))
                }
                return
            }
            
            let context = ProfileChangeError.Context(authenticatedUser: authenticatedUser, profileChangeType: .updatePassword(newPassword))
            self.handleProfileChangeFirebaseError(error, context: context, passwordForReauthentication: passwordForReauthentication, completion: completion)
        }
    }
    
    /// Unlinks the specified provider from the currently signed in user.
    public func unlinkFrom(providerID: IdentityProviderID, completion: @escaping ProfileChangeHandler) {
        guard let authenticatedUser = authenticatedUser else {
            return
        }
        
        // first validate that the user will still have other sign-in options available if the unlinking is allowed to continue
        if linkedProviders.filter({$0.providerID != providerID }).isEmpty {
            let context = ProfileChangeError.Context(authenticatedUser: authenticatedUser, profileChangeType: .unlinkFromProvider(providerID))
            completion(.failure(.requiresAtLeastOneSignInMethod(context)))
        }
        else {
            authenticatedUser.unlink(fromProvider: providerID.rawValue) { (user, error) in
                guard let error = error else {
                    // ensure the user is refreshed
                    authenticatedUser.reload() { (_) in
                        completion(.success(authenticatedUser))
                    }
                    return
                }
                
                let context = ProfileChangeError.Context(authenticatedUser: authenticatedUser, profileChangeType: .unlinkFromProvider(providerID))
                self.handleProfileChangeFirebaseError(error, context: context, completion: completion)
            }
        }
    }
    
    /// Enqueues a delete account operation.
    public func deleteAccount(with op: DeleteAccountOperation) {
        // raise flag
        accountDeletionQueue.addOperation { self.isDeletingUserAccount = true }
        
        // add account deletion op
        accountDeletionQueue.addOperation(op)
        
        // lower flag
        accountDeletionQueue.addOperation { self.isDeletingUserAccount = false }
    }
    
}

extension AuthManager {
    func deleteAccount(with completion: @escaping ProfileChangeHandler) {
        guard let authenticatedUser = authenticatedUser else {
            return
        }
        
        authenticatedUser.delete { (error) in
            guard let error = error else {
                completion(.success(authenticatedUser))
                return
            }
            
            let context = ProfileChangeError.Context(authenticatedUser: authenticatedUser, profileChangeType: .deleteAccount)
            self.handleProfileChangeFirebaseError(error, context: context, completion: completion)
        }
    }
}

extension AuthManager {
    private func start() {
        Auth.auth().addStateDidChangeListener({ (auth, user) in
            if let user = user {
                self.authenticatedUser = user
                self.authenticationState = .authenticated
            }
            else {
                self.authenticatedUser = nil
                self.authenticationState = .notAuthenticated
                self.lastReauthenticationDate = nil
            }
            
            NotificationCenter.default.post(name: AuthManager.authenticationStateChangedNotification, object: self, userInfo: nil)
        })
    }
    
    private func reauthenticate<P: IdentityProvider>(with provider: P, completion: @escaping AuthResultHandler) {
        authenticationQueue.addOperation(AuthOperation(provider: provider, authenticationType: .reauthenticate) { (result, error) in
            guard let error = error else {
                completion(.success(result!))
                return
            }
            
            let context = AuthenticationError.Context(providerID: provider.providerID, authenticationType: .reauthenticate)
            self.handleAuthProcedureFirebaseError(error, context: context, provider: provider, completion: completion)
        })
    }
    
    private func handleAuthProcedureFirebaseError<P: IdentityProvider>(_ error: Error, context: AuthenticationError.Context, provider: P, completion: @escaping AuthResultHandler) {
        if let error = error as NSError? {
            if error.code == AuthErrorCode.emailAlreadyInUse.rawValue, provider.providerID == .email {
                // this error is only ever triggered when using the "createUserWithEmail" method
                // in Firebase; in other words, this error is only triggered when the user tries
                // to sign up for an email account
                let email = (provider as! EmailIdentityProvider).email
                Auth.auth().fetchSignInMethods(forEmail: email) { (providers, fetchError) in
                    // note that unless the email address passed to this method, we don't expect
                    // to run into any errors (other than typical network connection errors)
                    
                    // get all providers that are not the one that the user just tried authenticating with
                    if let providers = providers?.compactMap({ IdentityProviderID(rawValue: $0) }).filter({ $0 != provider.providerID }), !providers.isEmpty {
                        completion(.failure(.requiresAccountLinking(providers, context)))
                    }
                    else {
                        completion(.failure(.emailBasedAccountAlreadyExists(context)))
                    }
                }
            }
            else if error.code == AuthErrorCode.wrongPassword.rawValue, provider.providerID == .email {
                let email = (provider as! EmailIdentityProvider).email
                Auth.auth().fetchSignInMethods(forEmail: email) { (providers, fetchError) in
                    // note that unless the email address passed to this method was not provided by the
                    // Firebase error, we don't expect to run into any errors (other than typical
                    // network connection errors)
                    
                    // get all providers that are not the one that the user just tried authenticating with
                    
                    // note this case is a little different from the other potential account linking scenarios
                    // in that the error could actually be a "wrong password" (reported by Firebase error), but
                    // it may also be a situation that requires account linking (a sign in via email was attempted
                    // even though there is no email based account, but there is an account linked to a third
                    // party auth provider that is using the same email) - this scenario can be identified by
                    // detecting the lack of an email based sign in method associated with this email account
                    if let providers = providers?.compactMap({ IdentityProviderID(rawValue: $0) }), !providers.contains(.email) {
                        let nonEmailProviders = providers.filter({ $0 != provider.providerID })
                        completion(.failure(.requiresAccountLinking(nonEmailProviders, context)))
                    }
                    else {
                        completion(.failure(.invalidEmailOrPassword(context)))
                    }
                }
            }
            else if error.code == AuthErrorCode.accountExistsWithDifferentCredential.rawValue {
                let email =  error.userInfo[AuthErrorUserInfoEmailKey] as! String
                Auth.auth().fetchSignInMethods(forEmail: email) { (providers, fetchError) in
                    // note that unless the email address passed to this method, we don't expect
                    // to run into any errors (other than typical network connection errors)
                    
                    // get all providers that are not the one that the user just tried authenticating with
                    if let providers = providers?.compactMap({ IdentityProviderID(rawValue: $0) }).filter({ $0 != provider.providerID }), !providers.isEmpty {
                        completion(.failure(.requiresAccountLinking(providers, context)))
                    }
                    else {
                        let msg = fetchError?.localizedDescription ?? "No error message provided. Account exists with different credential."
                        completion(.failure(.other(msg, context)))
                    }
                }
            }
            else if error.code == AuthErrorCode.userNotFound.rawValue {
                completion(.failure(.invalidEmailOrPassword(context)))
            }
            else if error.code == AuthErrorCode.providerAlreadyLinked.rawValue {
                completion(.failure(.providerAlreadyLinked(context)))
            }
            else {
                let msg = error.localizedDescription
                completion(.failure(.other(msg, context)))
            }
        }
    }
    
    private func handleProfileChangeFirebaseError(_ error: Error, context: ProfileChangeError.Context, passwordForReauthentication: String? = nil, completion: @escaping ProfileChangeHandler) {
        if let error = error as NSError? {
            if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                if let passwordForReauthentication = passwordForReauthentication,
                    let linkedEmailProviderUserInfo = linkedEmailProviderUserInfo,
                    let email = linkedEmailProviderUserInfo.email {
                    let challenge = ProfileChangeReauthenticationChallenge(context: context, completion: completion)
                    
                    // attempt silently reauthenticating via the linked email provider
                    // using the provided password
                    let provider = EmailIdentityProvider(email: email, password: passwordForReauthentication)
                    reauthenticate(with: provider, for: challenge)
                }
                else if let reauthenticator = reauthenticator {
                    // 1. notify the delegate that we need to reauthenticate
                    // 2. after a successful reauthentication, we need to continue the profile change and eventually call the completion handler
                    let challenge = ProfileChangeReauthenticationChallenge(context: context, completion: completion)
                    reauthenticator.authManager(self, reauthenticateUsing: self.linkedProviders, challenge: challenge)
                }
                else {
                    completion(.failure(.requiresRecentSignIn(context)))
                }
            }
            else if error.code == AuthErrorCode.noSuchProvider.rawValue {
                completion(.failure(.noSuchProvider(context)))
            }
            else {
                let msg = error.localizedDescription
                completion(.failure(.other(msg, context)))
            }
        }
        else {
            let authenticatedUser = context.authenticatedUser
            completion(.success(authenticatedUser))
        }
    }
}
