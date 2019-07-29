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

/// The block that is invoked when a sign-in related event completes. The parameter
/// passed to the block is an `AuthManager.Result` object that may indicate that a
/// further user action is required.
public typealias ResultHandler<P: IdentityProvider> = (Result<AuthDataResult, AuthenticationError<P>>) -> Void



public class AuthManager {
    public enum State {
        case notDetermined
        case notAuthenticated
        case authenticated
    }
    
    /// Posted on the main queue when the authentication state changes.
    public static let authenticationStateChangedNotification = Notification.Name("firebaseidentity.authmanager.authenticationstatechangednotification")
    
    /// The shared instance.
    public static let shared = AuthManager()
    
    /// The authentication state of the receiver.
    public private(set) var state = State.notDetermined
    
    /// The currently authenticated user, or nil if user is not authenticated.
    public private(set) var authenticatedUser: User?
    
    private func start() {
        Auth.auth().addStateDidChangeListener({ (auth, user) in
            if let user = user {
                self.authenticatedUser = user
                self.state = .authenticated
            }
            else {
                self.authenticatedUser = nil
                self.state = .notAuthenticated
            }
            
            NotificationCenter.default.post(name: AuthManager.authenticationStateChangedNotification, object: self, userInfo: nil)
        })
    }
}

extension AuthManager {
    public func signUp<P: IdentityProvider>(with provider: P, completion: @escaping ResultHandler<P>) {
        provider.signUp { (result, error) in
            guard let error = error else {
                completion(.success(result!))
                return
            }
            
            let context = AuthenticationError.Context(provider: provider, authenticationType: .signUp)
            self.handleAuthResponse(for: error, context: context, completion: completion)
        }
    }
    
    public func signIn<P: IdentityProvider>(with provider: P, completion: @escaping ResultHandler<P>) {
        provider.signIn { (result, error) in
            guard let error = error else {
                completion(.success(result!))
                return
            }
            
            let context = AuthenticationError.Context(provider: provider, authenticationType: .signIn)
            self.handleAuthResponse(for: error, context: context, completion: completion)
        }
    }
    
    private func handleAuthResponse<P: IdentityProvider>(for error: Error, context: AuthenticationError<P>.Context, completion: @escaping ResultHandler<P>) {
        let provider = context.provider
        
        if let error = error as NSError? {
            if error.code == AuthErrorCode.emailAlreadyInUse.rawValue, provider.providerID == .email {
                // this error is only ever is specifically triggered when using the "createUserWithEmail" method
                // in Firebase; in other words, this error is only triggered when the user tries to sign up for
                // an email account
                let email = (provider as! EmailIdentityProvider).email
                Auth.auth().fetchSignInMethods(forEmail: email) { (providers, fetchError) in
                    // note that unless the email address passed to this method, we don't expect
                    // to run into any errors (other than typical network connection errors)
                    
                    // since the app currently only support 2 providers (email, facebook), there can
                    // only ever be a single providerID returned here, therefore we'll just access the
                    // first item in the array
                    
                    // get all providers that are not the one that the user just tried authenticating with
                    if let providerID = providers?.compactMap({ IdentityProviderID(rawValue: $0) }).filter({ $0 != provider.providerID }).first {
                        completion(.failure(.requiresAccountLinking(providerID, context)))
                    }
                    else {
                        completion(.failure(.emailBasedAccountAlreadyExists(context)))
                    }
                }
            }
            else if error.code == AuthErrorCode.accountExistsWithDifferentCredential.rawValue {
                let email =  error.userInfo[AuthErrorUserInfoEmailKey] as! String
                Auth.auth().fetchSignInMethods(forEmail: email) { (providers, fetchError) in
                    // note that unless the email address passed to this method, we don't expect
                    // to run into any errors (other than typical network connection errors)
                    
                    // since the app currently only support 2 providers (email, facebook), there can
                    // only ever be a single providerID returned here, therefore we'll just access the
                    // first item in the array
                    
                    // get all providers that are not the one that the user just tried authenticating with
                    if let providerID = providers?.compactMap({ IdentityProviderID(rawValue: $0) }).filter({ $0 != provider.providerID }).first {
                        completion(.failure(.requiresAccountLinking(providerID, context)))
                    }
                    else {
                        let message = fetchError?.localizedDescription ?? "No error message provided. Account exists with different credential."
                        completion(.failure(.other(message, context)))
                    }
                }
            }
            else if error.code == AuthErrorCode.wrongPassword.rawValue, provider.providerID == .email {
                let email = (provider as! EmailIdentityProvider).email
                Auth.auth().fetchSignInMethods(forEmail: email) { (providers, fetchError) in
                    // note that unless the email address passed to this method, we don't expect
                    // to run into any errors (other than typical network connection errors)
                    
                    // since the app currently only support 2 providers (email, facebook), there can
                    // only ever be a single providerID returned here, therefore we'll just access the
                    // first item in the array
                    
                    // get all providers that are not the one that the user just tried authenticating with
                    if let providerID = providers?.compactMap({ IdentityProviderID(rawValue: $0) }).filter({ $0 != provider.providerID }).first {
                        completion(.failure(.requiresAccountLinking(providerID, context)))
                    }
                    else {
                        completion(.failure(.invalidEmailOrPassword(context))) // actually a wrong password
                    }
                }
            }
            else if error.code == AuthErrorCode.userNotFound.rawValue {
                completion(.failure(.invalidEmailOrPassword(context)))
            }
            else {
                let message = error.localizedDescription
                completion(.failure(.other(message, context)))
            }
        }
    }
}

extension AuthManager {
    public static func configure() {
        AuthManager.shared.start()
    }
}
