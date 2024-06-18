//
//  AuthManager.swift
//
//  Copyright (c) 2024 Christian Gossain
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

import Combine
import FirebaseAuth
import Foundation
import ProcedureKit

/// The block that is invoked when an authentication related event completes. The parameter
/// passed to the block is an `AuthManager.Result` object that may indicate that a
/// further user action is required.
public typealias AuthOperationCompletionHandler = (Result<AuthDataResult, AuthenticationError>) -> Void

/// The block that is invoked when a profile change event completes.
public typealias ProfileChangeCompletionHandler = (Result<User, ProfileChangeError>) -> Void

/// The block that is optionally invoked when the `requestReauthentication()` method completes.
public typealias ReauthenticationRequestHandler = (AuthManager.ReauthenticationResult) -> Void

/// An object that manages all Firebase authentication and user related events.
public final class AuthManager {
    
    // MARK: - Types
    
    /// A type that provides metadata about an identity provider.
    public struct IdentityProviderUserInfo {
        
        /// The identity provider ID.
        public let providerID: IdentityProviderID
        
        /// The user ID.
        public let uid: String
        
        /// The email address.
        public let email: String?
        
        /// The display name.
        public let displayName: String?
    }
    
    /// The reauthentication result.
    public enum ReauthenticationResult {
        case authenticated(User)
        case failure(ProfileChangeError)
    }
    
    // MARK: - Properties
    
    /// The default instance.
    ///
    /// This instance is initialized with the auth object for the default Firebase app.
    public static var `default`: AuthManager = {
        AuthManager(auth: Auth.auth())
    }()
    
    /// The Firebase auth object for a `FirebaseApp`.
    public let auth: Auth
    
    /// The authentication state of the receiver.
    @Published public private(set) var authState: AuthState = .notDetermined {
        didSet {
            NotificationCenter.default
                .post(
                    name: .authenticationStateChanged,
                    object: self,
                    userInfo: nil
                )
        }
    }
    
    /// The object that will handle reauthentication callbacks.
    public weak var reauthenticator: AuthManagerReauthenticating?
    
    /// The last authentication date of the currently signed in user (includes sign-ins and reauthentications).
    public var lastAuthenticationDate: Date? {
        guard case let .authenticated(authenticatedUser) = authState else {
            return nil
        }
        
        let dates = [
            authenticatedUser.metadata.lastSignInDate,
            lastReauthenticationDate
        ]
        return dates
            .compactMap { $0 }
            .sorted(by: >)
            .first
    }
    
    /// The list of identity providers associated with the currently authenticated user.
    ///
    /// If the user is not authenticated, returns and empty array.
    ///
    /// - Note: The providers are returned in sorted by the priority order specified in `providerReauthenticationPriority`.
    public var linkedProviders: [IdentityProviderUserInfo] {
        switch authState {
        case .notDetermined, .notAuthenticated:
            return []
            
        case .authenticated(let user):
            let providers: [IdentityProviderUserInfo] = user.providerData
                .compactMap({
                    guard let providerID = IdentityProviderID(rawValue: $0.providerID) else {
                        return nil
                    }
                    return IdentityProviderUserInfo(
                        providerID: providerID,
                        uid: $0.uid,
                        email: $0.email,
                        displayName: $0.displayName
                    )
                })
            
            // sort according to the priority order
            // https://stackoverflow.com/a/51683055/485352
            return providers
                .sorted {
                    guard let lhs = linkedProvidersPriority.firstIndex(of: $0.providerID) else {
                        return false
                    }
                    
                    guard let rhs = linkedProvidersPriority.firstIndex(of: $1.providerID) else {
                        return true
                    }
                    
                    return lhs < rhs
                }
        }
    }
    
    /// The order of priority that identity providers should listed in the `linkedProviders` array.
    ///
    /// This array is used for things like reauthentication when needed.
    ///
    /// - Note: Defaults to `email` as the first provider.
    public var linkedProvidersPriority: [IdentityProviderID] = IdentityProviderID.allCases.sorted { (lhs, rhs) -> Bool in return lhs == .email }
    
    // MARK: - Init
    
    /// Initializer.
    public init(auth: Auth) {
        self.auth = auth
        addSubscriptions()
    }
    
    // MARK: - API
    
    /// Enqueues a sign up auth operation.
    public func signUp<P: IdentityProviding>(
        with provider: P,
        completion: @escaping AuthOperationCompletionHandler
    ) {
        enqueueAuthOperation(
            with: provider,
            authenticationType: .signUp,
            completion: completion
        )
    }
    
    /// Enqueues a sign in auth operation.
    public func signIn<P: IdentityProviding>(
        with provider: P,
        completion: @escaping AuthOperationCompletionHandler
    ) {
        enqueueAuthOperation(
            with: provider,
            authenticationType: .signIn,
            completion: completion
        )
    }
    
    /// Enqueues an account linking auth operation.
    public func linkWith<P: IdentityProviding>(
        with provider: P,
        completion: @escaping AuthOperationCompletionHandler
    ) {
        enqueueAuthOperation(
            with: provider,
            authenticationType: .link,
            completion: completion
        )
    }
    
    /// Enqueues a reauthentication auth operation.
    ///
    /// After a successful reauthentication, this method will retry the previously attempted operation contained in the challenge object.
    public func reauthenticate<P: IdentityProviding>(
        with provider: P,
        challenge: ProfileChangeReauthenticationChallenge,
        completion: AuthOperationCompletionHandler? = nil
    ) {
        enqueueAuthOperation(
            with: provider,
            authenticationType: .reauthenticate
        ) { result in
            switch result {
            case .success:
                self.lastReauthenticationDate = Date()
                
                // retry the profile change attempt that
                // failed using the error context
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
                // notify the completion handler associated with the challenge about the failure
                challenge.completion(.failure(.other(error.localizedDescription, challenge.context)))
            }
            
            // pass the result to the
            // completion handler if
            // provided
            completion?(result)
        }
    }
    
    /// Cancels a previously started reauthentication.
    public func cancelReauthentication(for challenge: ProfileChangeReauthenticationChallenge) {
        challenge.completion(.failure(.cancelledByUser(challenge.context)))
    }
    
    /// Requests reauthentication.
    ///
    /// If the user is not authenticated, this method is a no-op.
    ///
    /// - Parameters:
    ///     - passwordForReauthentication: If provided, and if the `requiresRecentLogin` Firebase error
    ///                                    is triggered, this password will be used to silently reauthenticate
    ///                                    the user via the `email` provider (if available); otherwise, reauthentication
    ///                                    occurs via the `reauthenticator` object if provided.
    ///     - completion: The completion handler.
    public func requestReauthentication(
        passwordForReauthentication: String? = nil,
        completion: @escaping ReauthenticationRequestHandler
    ) {
        guard case let .authenticated(authenticatedUser) = authState else {
            // no-op
            return
        }
        
        if !needsReauthenticationForProfileChanges {
            completion(.authenticated(authenticatedUser))
            return
        }
        
        let context = ProfileChangeError.Context(authenticatedUser: authenticatedUser, profileChangeType: .requestReauthentication)
        if let passwordForReauthentication = passwordForReauthentication,
           let email = linkedEmailProviderUserInfo?.email {
            let challenge = ProfileChangeReauthenticationChallenge(context: context) { (result) in
                switch result {
                case .success(let user):
                    completion(.authenticated(user))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            
            // attempt silently reauthenticating via the linked email provider
            // using the provided password
            let provider = EmailIdentityProvider(email: email, password: passwordForReauthentication)
            reauthenticate(with: provider, challenge: challenge)
        } else if let reauthenticator = reauthenticator {
            // 1. notify the delegate that we need to reauthenticate
            // 2. after a successful reauthentication, we need to continue the profile change and eventually call the completion handler
            let challenge = ProfileChangeReauthenticationChallenge(context: context) { (result) in
                switch result {
                case .success(let user):
                    completion(.authenticated(user))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            reauthenticator.authManager(self, reauthenticateUsing: self.linkedProviders, challenge: challenge)
        } else {
            completion(.failure(.missingReauthenticationMethod(context)))
        }
    }
    
    /// Signs out the current user.
    public func signOut() {
        try? auth.signOut()
    }
    
    /// Updates the display name of the currently signed in user.
    ///
    /// If the user is not authenticated, this method is a no-op.
    ///
    /// - Parameters:
    ///     - newEmail: The new display name for the user.
    ///     - passwordForReauthentication: If provided, and if the `requiresRecentLogin` Firebase error
    ///                                    is triggered, this password will be used to silently reauthenticate
    ///                                    the user via the `email` provider (if available); otherwise, reauthentication
    ///                                    occurs via the `reauthenticator` object if provided.
    ///     - completion: The completion handler.
    public func updateDisplayName(
        to newDisplayName: String,
        passwordForReauthentication: String? = nil,
        completion: @escaping ProfileChangeCompletionHandler
    ) {
        guard case let .authenticated(authenticatedUser) = authState else {
            // no-op
            return
        }
        
        let profileChangeRequest = authenticatedUser.createProfileChangeRequest()
        profileChangeRequest.displayName = newDisplayName
        profileChangeRequest.commitChanges { (error) in
            guard let error = error else {
                // sync the user's profile
                // data from the server
                authenticatedUser.reload() { (_) in
                    completion(.success(authenticatedUser))
                }
                return
            }
            
            let context = ProfileChangeError.Context(authenticatedUser: authenticatedUser, profileChangeType: .updateDisplayName(newDisplayName))
            self.handleProfileChangeError(error, context: context, passwordForReauthentication: passwordForReauthentication, completion: completion)
        }
    }
    
    /// Updates the email address of the currently signed in user.
    ///
    /// If the user is not authenticated, this method is a no-op.
    ///
    /// - Parameters:
    ///     - newEmail: The new email address for the user.
    ///     - passwordForReauthentication: If provided, and if the `requiresRecentLogin` Firebase error
    ///                                    is triggered, this password will be used to silently reauthenticate
    ///                                    the user via the `email` provider (if available); otherwise, reauthentication
    ///                                    occurs via the `reauthenticator` object if provided.
    ///     - completion: The completion handler.
    public func updateEmail(
        to newEmail: String,
        passwordForReauthentication: String? = nil,
        completion: @escaping ProfileChangeCompletionHandler
    ) {
        guard case let .authenticated(authenticatedUser) = authState else {
            // no-op
            return
        }
        
        authenticatedUser.updateEmail(to: newEmail) { (error) in
            guard let error = error else {
                // sync the user's profile
                // data from the server
                authenticatedUser.reload() { (_) in
                    completion(.success(authenticatedUser))
                }
                return
            }
            
            let context = ProfileChangeError.Context(authenticatedUser: authenticatedUser, profileChangeType: .updateEmail(newEmail))
            self.handleProfileChangeError(error, context: context, passwordForReauthentication: passwordForReauthentication, completion: completion)
        }
    }
    
    /// Updates (or sets) the password of the currently signed in user.
    ///
    /// If the user is not authenticated, this method is a no-op.
    ///
    /// - Parameters:
    ///     - newPassword: The new password for the user.
    ///     - passwordForReauthentication: If provided, and if the `requiresRecentLogin` Firebase error
    ///                                    is triggered, this password will be used to silently reauthenticate
    ///                                    the user via the `email` provider (if available); otherwise, reauthentication
    ///                                    occurs via the `reauthenticator` object if provided.
    ///     - completion: The completion handler.
    public func updatePassword(
        to newPassword: String,
        passwordForReauthentication: String? = nil,
        completion: @escaping ProfileChangeCompletionHandler
    ) {
        guard case let .authenticated(authenticatedUser) = authState else {
            // no-op
            return
        }
        
        authenticatedUser.updatePassword(to: newPassword) { (error) in
            guard let error = error else {
                // sync the user's profile
                // data from the server
                authenticatedUser.reload() { (_) in
                    completion(.success(authenticatedUser))
                }
                return
            }
            
            let context = ProfileChangeError.Context(authenticatedUser: authenticatedUser, profileChangeType: .updatePassword(newPassword))
            self.handleProfileChangeError(error, context: context, passwordForReauthentication: passwordForReauthentication, completion: completion)
        }
    }
    
    /// Unlinks the specified provider from the currently signed in user.
    ///
    /// If the user is not authenticated, this method is a no-op.
    ///
    /// - Parameters:
    ///     - providerID: The ID of the provider to unlink from.
    ///     - completion: The completion handler.
    public func unlinkFrom(
        providerID: IdentityProviderID,
        completion: @escaping ProfileChangeCompletionHandler
    ) {
        guard case let .authenticated(authenticatedUser) = authState else {
            // no-op
            return
        }
        
        // first validate that the user will still have other sign-in options available if the unlinking is allowed to continue
        if linkedProviders.filter({$0.providerID != providerID }).isEmpty {
            let context = ProfileChangeError.Context(authenticatedUser: authenticatedUser, profileChangeType: .unlinkFromProvider(providerID))
            completion(.failure(.requiresAtLeastOneSignInMethod(context)))
        } else {
            authenticatedUser.unlink(fromProvider: providerID.rawValue) { (user, error) in
                guard let error = error else {
                    // sync the user's profile
                    // data from the server
                    authenticatedUser.reload() { (_) in
                        completion(.success(authenticatedUser))
                    }
                    return
                }
                
                let context = ProfileChangeError.Context(authenticatedUser: authenticatedUser, profileChangeType: .unlinkFromProvider(providerID))
                self.handleProfileChangeError(error, context: context, completion: completion)
            }
        }
    }
    
    /// Deletes the user account (also signs out the user, if this was the current user).
    ///
    /// If the user is not authenticated, this method is a no-op.
    ///
    /// - Parameters:
    ///     - completion: The completion handler.
    public func deleteAccount(with completion: @escaping ProfileChangeCompletionHandler) {
        guard case let .authenticated(authenticatedUser) = authState else {
            // no-op
            return
        }
        
        authenticatedUser.delete { [unowned self] (error) in
            guard let error = error else {
                completion(.success(authenticatedUser))
                return
            }
            
            let context = ProfileChangeError.Context(authenticatedUser: authenticatedUser, profileChangeType: .deleteAccount)
            self.handleProfileChangeError(error, context: context, completion: completion)
        }
    }
    
    // MARK: - Helpers
    
    private func addSubscriptions() {
        auth.addStateDidChangeListener { (auth, user) in
            if let user {
                self.authState = .authenticated(user)
            } else {
                self.authState = .notAuthenticated
                self.lastReauthenticationDate = nil
            }
        }
    }
    
    private func enqueueAuthOperation<P: IdentityProviding>(
        with provider: P,
        authenticationType: AuthType,
        completion: @escaping AuthOperationCompletionHandler
    ) {
        authenticationQueue.addOperation(
            AuthOperation<P>(
                auth: auth,
                provider: provider,
                authenticationType: authenticationType
            ) { (result, error) in
                guard let error = error else {
                    completion(.success(result!))
                    return
                }
                
                let context = AuthenticationError.Context(providerID: provider.providerID, authenticationType: authenticationType)
                self.handleAuthOperationError(error, context: context, provider: provider, completion: completion)
            }
        )
    }
    
    private func handleAuthOperationError<P: IdentityProviding>(
        _ error: Error,
        context: AuthenticationError.Context,
        provider: P,
        completion: @escaping AuthOperationCompletionHandler
    ) {
        if let error = error as NSError? {
            if error.code == AuthErrorCode.emailAlreadyInUse.rawValue, provider.providerID == .email {
                // this error is only ever triggered when using the `auth.createUser` method
                // in Firebase
                //
                // in other words, this error is only triggered when the user tries
                // to "sign up" for an email based account
                let email = (provider as! EmailIdentityProvider).email
                auth.fetchSignInMethods(forEmail: email) { (providers, fetchError) in
                    // get all providers that are not the one that the user just tried authenticating with
                    if let providers = providers?.compactMap(IdentityProviderID.init).filter({ $0 != provider.providerID }), !providers.isEmpty, fetchError == nil {
                        completion(.failure(.requiresAccountLinking(email, providers, context)))
                    } else {
                        completion(.failure(.emailBasedAccountAlreadyExists(context)))
                    }
                }
            } else if error.code == AuthErrorCode.wrongPassword.rawValue, provider.providerID == .email {
                let email = (provider as! EmailIdentityProvider).email
                auth.fetchSignInMethods(forEmail: email) { (providers, fetchError) in
                    // get all providers that are not the one that the user just tried authenticating with
                    
                    // note this case is a little different from the other potential account linking scenarios
                    // in that the error could actually be a "wrong password" (reported by Firebase error), but
                    // it may also be a situation that requires account linking (a sign in via email was attempted
                    // even though there is no email based account, but there is an account linked to a third
                    // party auth provider that is using the same email) - this scenario can be identified by
                    // detecting the lack of an email based sign in method associated with this email account
                    if let providers = providers?.compactMap(IdentityProviderID.init), !providers.contains(.email), fetchError == nil {
                        let nonEmailProviders = providers.filter({ $0 != provider.providerID })
                        completion(.failure(.requiresAccountLinking(email, nonEmailProviders, context)))
                    } else {
                        completion(.failure(.invalidEmailOrPassword(context)))
                    }
                }
            } else if error.code == AuthErrorCode.accountExistsWithDifferentCredential.rawValue {
                let email =  error.userInfo[AuthErrorUserInfoEmailKey] as! String
                auth.fetchSignInMethods(forEmail: email) { (providers, fetchError) in
                    // get all providers that are not the one that the user just tried authenticating with
                    if let providers = providers?.compactMap(IdentityProviderID.init).filter({ $0 != provider.providerID }), !providers.isEmpty, fetchError == nil {
                        completion(.failure(.requiresAccountLinking(email, providers, context)))
                    } else {
                        let msg = fetchError?.localizedDescription ?? "No error message provided. Account exists with different credential."
                        completion(.failure(.other(msg, context)))
                    }
                }
            } else if error.code == AuthErrorCode.userNotFound.rawValue {
                completion(.failure(.invalidEmailOrPassword(context)))
            } else if error.code == AuthErrorCode.providerAlreadyLinked.rawValue {
                completion(.failure(.providerAlreadyLinked(context)))
            } else {
                let msg = error.localizedDescription
                completion(.failure(.other(msg, context)))
            }
        }
    }
    
    private func handleProfileChangeError(
        _ error: Error,
        context: ProfileChangeError.Context,
        passwordForReauthentication: String? = nil,
        completion: @escaping ProfileChangeCompletionHandler
    ) {
        if let error = error as NSError? {
            if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                if let passwordForReauthentication = passwordForReauthentication,
                   let linkedEmailProviderUserInfo = linkedEmailProviderUserInfo,
                   let email = linkedEmailProviderUserInfo.email {
                    let challenge = ProfileChangeReauthenticationChallenge(context: context, completion: completion)
                    
                    // attempt silently reauthenticating via the linked email provider
                    // using the provided password
                    let provider = EmailIdentityProvider(email: email, password: passwordForReauthentication)
                    reauthenticate(with: provider, challenge: challenge)
                } else if let reauthenticator {
                    // 1. notify the delegate that we need to reauthenticate
                    // 2. after a successful reauthentication, we need to continue the profile change and eventually call the completion handler
                    let challenge = ProfileChangeReauthenticationChallenge(context: context, completion: completion)
                    reauthenticator.authManager(self, reauthenticateUsing: self.linkedProviders, challenge: challenge)
                } else {
                    completion(.failure(.requiresRecentSignIn(context)))
                }
            } else if error.code == AuthErrorCode.noSuchProvider.rawValue {
                completion(.failure(.noSuchProvider(context)))
            } else {
                let msg = error.localizedDescription
                completion(.failure(.other(msg, context)))
            }
        } else {
            let authenticatedUser = context.authenticatedUser
            completion(.success(authenticatedUser))
        }
    }
    
    // MARK: - Private
    
    /// Returns the metadata of the linked email identity provider; otherwise `nil` if
    /// an email provider is not linked to the current user.
    private var linkedEmailProviderUserInfo: IdentityProviderUserInfo? { linkedProviders.filter({ $0.providerID == .email }).first }
    
    /// Indicates if reauthentication will be required to perform a profile change.
    ///
    /// You can use this property to preemptively reauthenticate before performing a profile change.
    ///
    /// Currently, this method checks if it's been more than 5 miunutes since the last authentication (which is the currently documented reauthentication requirement on the Firebase side).
    private var needsReauthenticationForProfileChanges: Bool {
        guard let lastAuthenticationDate else {
            return false
        }
        
        let components = Calendar
            .current
            .dateComponents([.minute], from: lastAuthenticationDate, to: Date())
        
        guard let minute = components.minute else {
            return false
        }
        
        return minute >= 5
    }
    
    /// The last reauthentication date of the currently signed in user.
    private var lastReauthenticationDate: Date? {
        get {
            UserDefaults
                .standard
                .value(forKey: "com.firebaseidentity.authmanager.lastreauthenticationdate") as? Date
        }
        set {
            UserDefaults
                .standard
                .set(newValue, forKey: "com.firebaseidentity.authmanager.lastreauthenticationdate")
        }
    }
    
    /// An internal operation queue for authentication operations (i.e., sign-up, sign-in, reauthentication, etc.,).
    ///
    /// The primary reason for using operations for authentication flows is that it provides a way to
    /// maintain a strong reference to the identity provider while the authentication flow is in
    /// progress. An additional benefit is that a serial queue allows us to run tasks in the
    /// same order they are submitted.
    private var authenticationQueue: ProcedureQueue = {
        let queue = ProcedureQueue()
        queue.name = "com.firebaseidentity.authmanager.authenticationqueue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
}
