//
//  AuthManager.swift
//  Firebase Identity
//
//  Created by Christian Gossain on 2019-02-15.
//  Copyright © 2019 MooveFit Technologies Inc. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import ProcedureKit

public enum Result<Value, Error: Swift.Error> {
    case success(Value)
    case failure(Error)
}

public extension Result {
    func resolve() throws -> Value {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}

/// The block that is invoked when an authentication related event completes. The parameter
/// passed to the block is an `AuthManager.Result` object that may indicate that a
/// further user action is required.
public typealias AuthResultHandler = (Result<AuthDataResult, AuthenticationError>) -> Void

/// The block that is invoked when a provider unlink event completes.
public typealias AuthUnlinkHandler = (Result<User, Error>) -> Void

/// The block that is invoked when a profile change event completes.
public typealias ProfileChangeHandler = (Result<User, ProfileChangeError>) -> Void

/// An object that provides context about the profile change that triggered the reauthentication challenge.
public struct ProfileChangeReauthenticationChallenge {
    public let context: ProfileChangeError.Context
    fileprivate let completion: ProfileChangeHandler
}

/// The auth manager delegate.
public protocol AuthManagerDelegate: class {
    /// Called when a reauthentication of the current user is required to perform an action. Your
    /// implementation should get an updated AuthCredential (e.g. via UI presented to the user), then
    /// call the auth manager's `reauthenticate` method.
    func authManager(_ manager: AuthManager, didReceive challenge: ProfileChangeReauthenticationChallenge)
}

/// An object that manages all Firebase authentication and user related events.
public class AuthManager {
    public enum State {
        case notDetermined
        case notAuthenticated
        case authenticated
    }
    
    /// Posted on the main queue when the authentication state changes.
    public static let authenticationStateChangedNotification = Notification.Name("com.firebaseidentity.authmanager.authenticationstatechangednotification")
    
    /// The shared instance.
    public static let shared = AuthManager()
    
    /// The object that receive delegate notifications.
    public weak var delegate: AuthManagerDelegate?
    
    /// The authentication state of the receiver.
    public private(set) var authenticationState = State.notDetermined
    
    /// The currently authenticated user, or nil if user is not authenticated.
    public private(set) var authenticatedUser: User?
    
    /// The list of identity providers associated with the currently authenticated user.
    public var linkedProviders: [IdentityProviderUserInfo] {
        return authenticatedUser?.providerData.compactMap({
            guard let providerID = IdentityProviderID(rawValue: $0.providerID) else {
                return nil
            }
            return IdentityProviderUserInfo(providerID: providerID, email: $0.email)
        }) ?? []
    }
    
    
    // MARK: - Private Properties
    /// An internal procedure queue for authentication procedures (i.e. sign-up, sign-in, reauthentication). This primary
    /// purpose for using procedure for authentication is that it provides a way to maintain a strong reference to the
    /// identity provider while the authentication action is in progress.
    fileprivate var authenticationProcedureQueue: ProcedureQueue = {
        let queue = ProcedureQueue()
        queue.name = "com.firebaseIdentity.authManager.authenticationProcedureQueue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    
    // MARK: - Lifecycle
    public static func configure() {
        AuthManager.shared.start()
    }
    
    private func start() {
        Auth.auth().addStateDidChangeListener({ (auth, user) in
            if let user = user {
                self.authenticatedUser = user
                self.authenticationState = .authenticated
            }
            else {
                self.authenticatedUser = nil
                self.authenticationState = .notAuthenticated
            }
            
            NotificationCenter.default.post(name: AuthManager.authenticationStateChangedNotification, object: self, userInfo: nil)
        })
    }
}

extension AuthManager {
    public func signUp<P: IdentityProvider>(with provider: P, completion: @escaping AuthResultHandler) {
        authenticationProcedureQueue.addOperation(AuthProcedure(provider: provider, authenticationType: .signUp) { (result, error) in
            guard let error = error else {
                completion(.success(result!))
                return
            }
            
            let context = AuthenticationError.Context(providerID: provider.providerID, authenticationType: .signUp)
            self.handleAuthProcedureError(error, context: context, provider: provider, completion: completion)
        })
    }
    
    public func signIn<P: IdentityProvider>(with provider: P, completion: @escaping AuthResultHandler) {
        authenticationProcedureQueue.addOperation(AuthProcedure(provider: provider, authenticationType: .signIn) { (result, error) in
            guard let error = error else {
                completion(.success(result!))
                return
            }
            
            let context = AuthenticationError.Context(providerID: provider.providerID, authenticationType: .signIn)
            self.handleAuthProcedureError(error, context: context, provider: provider, completion: completion)
        })
    }
    
    /// If reauthentication is successful, then the profile change that previously failed is automatically
    /// retried. If reauthentication fails, the error handler will fire.
    public func reauthenticate<P: IdentityProvider>(with provider: P, for challenge: ProfileChangeReauthenticationChallenge, errorHandler: @escaping (AuthenticationError) -> Void) {
        self.reauthenticate(with: provider) { (result) in
            switch result {
            case .success(_):
                // using the information in the challenge object, we can retry the profile change that had previously failed
                switch challenge.context.profileChangeType {
                case .email(let email):
                    self.updateEmail(to: email, completion: challenge.completion)
                    
                case .password(let password):
                    self.updatePassword(to: password, completion: challenge.completion)
                    
                case .unlinkProvider(_):
                    break // not retryable
                }
                
            case .failure(let error):
                errorHandler(error)
            }
        }
    }
    
    public func linkWith<P: IdentityProvider>(with provider: P, completion: @escaping AuthResultHandler) {
        authenticationProcedureQueue.addOperation(AuthProcedure(provider: provider, authenticationType: .linkProvider) { (result, error) in
            guard let error = error else {
                completion(.success(result!))
                return
            }
            
            let context = AuthenticationError.Context(providerID: provider.providerID, authenticationType: .linkProvider)
            self.handleAuthProcedureError(error, context: context, provider: provider, completion: completion)
        })
    }
    
    private func reauthenticate<P: IdentityProvider>(with provider: P, completion: @escaping AuthResultHandler) {
        authenticationProcedureQueue.addOperation(AuthProcedure(provider: provider, authenticationType: .reauthenticate) { (result, error) in
            guard let error = error else {
                completion(.success(result!))
                return
            }
            
            let context = AuthenticationError.Context(providerID: provider.providerID, authenticationType: .reauthenticate)
            self.handleAuthProcedureError(error, context: context, provider: provider, completion: completion)
        })
    }
    
    private func handleAuthProcedureError<P: IdentityProvider>(_ error: Error, context: AuthenticationError.Context, provider: P, completion: @escaping AuthResultHandler) {
        if let error = error as NSError? {
            if error.code == AuthErrorCode.emailAlreadyInUse.rawValue, provider.providerID == .email {
                // this error is only ever is specifically triggered when using the "createUserWithEmail" method
                // in Firebase; in other words, this error is only triggered when the user tries to sign up for
                // an email account
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
}

extension AuthManager {
    public func updateEmail(to email: String, completion: @escaping ProfileChangeHandler) {
        guard let authenticatedUser = authenticatedUser else {
            return
        }

        authenticatedUser.updateEmail(to: email) { (error) in
            guard let error = error else {
                // ensure the user is refreshed
                authenticatedUser.reload(completion: { (_) in
                    // a reload error is irrelevant, the update was successful regardless of the reload
                    completion(.success(authenticatedUser))
                })
                return
            }

            let context = ProfileChangeError.Context(authenticatedUser: authenticatedUser, profileChangeType: .email(email))
            self.handleProfileChangeError(error, context: context, completion: completion)
        }
    }
    
    public func updatePassword(to password: String, completion: @escaping ProfileChangeHandler) {
        guard let authenticatedUser = authenticatedUser else {
            return
        }
        
        authenticatedUser.updatePassword(to: password) { (error) in
            guard let error = error else {
                // ensure the user is refreshed
                authenticatedUser.reload(completion: { (_) in
                    // a reload error is irrelevant, the update was successful regardless of the reload
                    completion(.success(authenticatedUser))
                })
                return
            }
            
            let context = ProfileChangeError.Context(authenticatedUser: authenticatedUser, profileChangeType: .password(password))
            self.handleProfileChangeError(error, context: context, completion: completion)
        }
    }
    
    public func unlinkFrom(providerID: IdentityProviderID, completion: @escaping ProfileChangeHandler) {
        guard let authenticatedUser = authenticatedUser else {
            return
        }
        
        authenticatedUser.unlink(fromProvider: providerID.rawValue) { (user, error) in
            guard let error = error else {
                // ensure the user is refreshed
                authenticatedUser.reload(completion: { (_) in
                    // a reload error is irrelevant, the update was successful regardless of the reload
                    completion(.success(authenticatedUser))
                })
                return
            }
            
            let context = ProfileChangeError.Context(authenticatedUser: authenticatedUser, profileChangeType: .unlinkProvider(providerID))
            self.handleProfileChangeError(error, context: context, completion: completion)
        }
    }
    
    private func handleProfileChangeError(_ error: Error, context: ProfileChangeError.Context, completion: @escaping ProfileChangeHandler) {
        if let error = error as NSError? {
            if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                if let delegate = delegate {
                    // 1. notify the delegate that we need to reauthenticate
                    // 2. after a successful reauthentication, we need to continue the profile change and eventually call the completion handler
                    let challenge = ProfileChangeReauthenticationChallenge(context: context, completion: completion)
                    delegate.authManager(self, didReceive: challenge)
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
