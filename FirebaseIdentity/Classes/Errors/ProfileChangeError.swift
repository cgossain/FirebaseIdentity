//
//  ProfileChangeError.swift
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

public enum ProfileChangeError: Error {
    /// The context in which the error occurred.
    public struct Context {
        public enum ProfileChangeType {
            /// Indicates that reauthentication was manually requested via the `requestReauthentication()` method.
            case requestReauthentication
            
            /// Indicates that the user attempted to update their display name. As an associated
            /// value this case contains the email that the user attempted to set.
            case updateDisplayName(String)
            
            /// Indicates that the user attempted to update their email. As an associated
            /// value this case contains the email that the user attempted to set.
            case updateEmail(String)
            
            /// Indicates that the user attempted to update their password. As an
            /// associated value this case contains the password that the user attempted to set.
            case updatePassword(String)
            
            /// Indicates that the user attempted to unlink an auth provider. As an
            /// associated value, this case contains the ID of the identity provider
            /// the user attempted to unlink from.
            case unlinkFromProvider(IdentityProviderID)
            
            /// Indicates that the user tried to delete their account.
            case deleteAccount
        }
        
        /// The identity provider that was used to authenticate.
        public let authenticatedUser: User
        
        /// The type of profile update that was attempted.
        public let profileChangeType: ProfileChangeType
        
        /// Creates a new context with the given identity provider and authentication type.
        ///
        /// - parameters:
        ///     - authenticatedUser: The Firebase user on which the profile update was attempted (this should be the currently authenticated user)
        ///     - profileChangeType: The type of profile change that was attempted.
        public init(authenticatedUser: User, profileChangeType: ProfileChangeType) {
            self.authenticatedUser = authenticatedUser
            self.profileChangeType = profileChangeType
        }
    }
    
    /// Can be trigged by Firebase error 17014
    ///
    /// An indication that the user tried to perform a security sensitive action that requires them to have
    /// recently signed in. These actions include: deleting an account, setting a primary email address, and changing a password.
    ///
    /// This case can be handled by reauthenticating the user.
    /// https://firebase.google.com/docs/auth/ios/manage-users?authuser=1#re-authenticate_a_user
    ///
    /// As an associated value, this case contains the context for debugging.
    case requiresRecentSignIn(ProfileChangeError.Context)
    
    /// Can be trigged by Firebase error 17016
    ///
    /// An indication that the user tried to unlink a provider that is not linked.
    ///
    /// As an associated value, this case contains the context for debugging.
    case noSuchProvider(ProfileChangeError.Context)
    
    /// Indicates that an attempt was made to unlink the only linked identity provider.
    ///
    /// The user must always have at least one associated identity provider. To handle this error, the user should ensure both an email and password are set to configure the email provider (which can't be unlinked).
    ///
    /// As an associated value, this case contains the context for debugging.
    case requiresAtLeastOneSignInMethod(ProfileChangeError.Context)
    
    /// Indicates that a reauthentication request could not be completed due to reauthentication methods not being available.
    ///
    /// Specifically this would be triggered when the `requestReauthentication()` method is used. This can happen
    /// if a `passwordForReauthentication` is provided but there is no linked email identity provider associated with
    /// the currently authenticated user. This can also be triggered if a `reauthenticator` object has not been set.
    case missingReauthenticationMethod(ProfileChangeError.Context)
    
    /// Indicates that the profile change was cancelled by the user.
    ///
    /// As an associated value, this case contains the context for debugging.
    case cancelledByUser(ProfileChangeError.Context)
    
    /// An indication that a general error has occured.
    ///
    /// As an associated value, this case contains the error message and context for debugging.
    case other(String, ProfileChangeError.Context)
}

extension ProfileChangeError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .requiresRecentSignIn(_):
            let msg = LocalizedString("This is a security sensitive action and requires a recent sign-in.", comment: "profile change error description")
            return msg
        case .noSuchProvider(_):
            let msg = LocalizedString("The provider is not linked.", comment: "profile change error description")
            return msg
        case .requiresAtLeastOneSignInMethod(let context):
            let providerDescription = context.profileChangeType.attemptedValue
            let msgFormat = LocalizedString("You must have at least one sign-in method enabled. Please enable another sign-in method before unlinking your %@ account.", comment: "profile change error description")
            let msg = String(format: msgFormat, providerDescription)
            return msg
        case .missingReauthenticationMethod(_):
            let msg = LocalizedString("There are no reauthentication methods available to perform this action.", comment: "profile change error description")
            return msg
        case .cancelledByUser(_):
            let msg = LocalizedString("The profile change was cancelled by the user.", comment: "profile change error description")
            return msg
        case .other(let message, _):
            let msg = "\(message)"
            return msg
        }
    }
}

extension ProfileChangeError.Context.ProfileChangeType {
    public var attemptedValue: String {
        switch self {
        case .updateDisplayName(let dp):
            return dp
        case .updateEmail(let email):
            return email
        case .updatePassword(let password):
            return password
        case .unlinkFromProvider(let providerID):
            return providerID.description
        default:
            return "n/a"
        }
    }
}
