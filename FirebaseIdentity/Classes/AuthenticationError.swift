//
//  AuthenticationError.swift
//  Firebase Identity
//
//  Created by Christian Gossain on 2019-02-24.
//

import Foundation

enum AuthenticationError<P: IdentityProvider>: Error {
    /// The context in which the error occurred.
    struct Context {
        enum AuthenticationType {
            case signUp
            case signIn
        }
        
        /// The identity provider that was used to authenticate.
        let provider: P
        
        /// The type of authentication that was attempted.
        let authenticationType: AuthenticationType
        
        /// Creates a new context with the given identity provider and authentication type.
        ///
        /// - parameters:
        ///     - provider: The identity provider that was used to authenticate.
        ///     - authenticationType: The type of authentication that was attempted.
        init(provider: P, authenticationType: AuthenticationType) {
            self.provider = provider
            self.authenticationType = authenticationType
        }
    }
    
    /// An indication that there the email address associated with the given identity provider is already in
    /// use by another account.
    ///
    /// This case can be handled by signing into the existing account and then linking to the given
    /// identity provider credentials.
    ///
    /// As associated values, this case contains the ID of the existing conflicting identity provider
    /// and context for debugging.
    case requiresAccountLinking(IdentityProviderID, AuthenticationError.Context)
    
    /// An indication that the email or password was provided during sign-in.
    ///
    /// As an associated value, this case contains the context for debugging.
    case invalidEmailOrPassword(AuthenticationError.Context)
    
    /// An indication that an general error has occured.
    ///
    /// As an associated value, this case contains the context for debugging.
    case other(AuthenticationError.Context)
}
