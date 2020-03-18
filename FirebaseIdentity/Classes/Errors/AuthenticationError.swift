//
//  AuthenticationError.swift
//
//  Copyright (c) 2019-2020 Christian Gossain
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

public enum AuthenticationType {
    case signUp
    case signIn
    case reauthenticate
    case linkProvider
}

public enum AuthenticationError: Error {
    /// The context in which the error occurred.
    public struct Context {
        /// The identity provider that was used to authenticate.
        public let providerID: IdentityProviderID
        
        /// The type of authentication that was attempted.
        public let authenticationType: AuthenticationType
        
        /// Creates a new context with the given identity provider and authentication type.
        ///
        /// - parameters:
        ///     - providerID: The identity provider that was used to authenticate.
        ///     - authenticationType: The type of authentication that was attempted.
        public init(providerID: IdentityProviderID, authenticationType: AuthenticationType) {
            self.providerID = providerID
            self.authenticationType = authenticationType
        }
    }
    
    /// Can be trigged by Firebase errors 17007, 17009, 17012
    ///
    /// An indication that there the email address associated with the attempted identity provider is
    /// already in use by another account.
    ///
    /// This case can be handled by signing into the existing account using one of the auth providers specified by this
    /// error and then linking the attempted credentials (available in the identity provider in the error context)
    ///
    /// As associated values, this case contains the list of available auth providers associated with
    /// the existing account and context for debugging.
    case requiresAccountLinking([IdentityProviderID], AuthenticationError.Context)
    
    /// Can be trigged by Firebase errors 17009, 17011
    ///
    /// An indication that an invalid email or password was provided during sign-in.
    ///
    /// As an associated value, this case contains the context for debugging.
    case invalidEmailOrPassword(AuthenticationError.Context)
    
    /// Can be trigged by Firebase error 17007
    ///
    /// An indication that an email based sign-up was attempted, but an email based account already
    /// exists with the same email address.
    ///
    /// As an associated value, this case contains the context for debugging.
    case emailBasedAccountAlreadyExists(AuthenticationError.Context)
    
    /// Can be trigged by Firebase error 17015
    ///
    /// An indication that an attempt was made to link a provider that is already linked to another account.
    /// UserInfo:?
    ///
    /// As an associated value, this case contains the context for debugging.
    case providerAlreadyLinked(AuthenticationError.Context)
    
    /// An indication that a general error has occured.
    ///
    /// As associated values, this case contains the error message and context for debugging.
    case other(String, AuthenticationError.Context)
}

extension AuthenticationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .requiresAccountLinking(_, _):
            let msg = LocalizedString("Account linking required.", comment: "auth error description")
            return msg
        case .invalidEmailOrPassword(_):
            let msg = LocalizedString("Invalid email or password.", comment: "auth error description")
            return msg
        case .emailBasedAccountAlreadyExists(_):
            let msg = LocalizedString("The email entered is already associated with an account. Please try a different email.", comment: "auth error description")
            return msg
        case .providerAlreadyLinked(_):
            let msg = LocalizedString("A user can only be linked to one identity for the given provider.", comment: "auth error description")
            return msg
        case .other(let message, _):
            let msg = "\(message)"
            return msg
        }
    }
}
