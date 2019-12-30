//
//  ProfileChangeError.swift
//  AppController
//
//  Created by Christian Gossain on 2019-08-05.
//

import Foundation
import FirebaseCore
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
    
    /// An indication that a general error has occured.
    ///
    /// As an associated value, this case contains the error message and context for debugging.
    case other(String, ProfileChangeError.Context)
}

extension ProfileChangeError.Context.ProfileChangeType {
    public var attemptedValue: String {
        switch self {
        case .updateEmail(let email):
            return email
        case .updatePassword(let password):
            return password
        case .unlinkFromProvider(let providerID):
            return providerID.rawValue
        default:
            return "n/a"
        }
    }
}

extension ProfileChangeError {
    public var localizedDescription: String {
        switch self {
        case .missingReauthenticationMethod(let context):
            let msg = LocalizedString("There are no reauthentication methods available to perform this action.", comment: "profile change error description")
            return msg
        case .cancelledByUser(let context):
            let msg = LocalizedString("The profile change was cancelled by the user.", comment: "profile change error description")
            return msg
        case .requiresRecentSignIn(let context):
            let msg = LocalizedString("This is a security sensitive action and requires a recent sign-in.", comment: "profile change error description")
            return msg
        case .noSuchProvider(let context):
            let msg = LocalizedString("The provider is not linked.", comment: "profile change error description")
            return msg
        case .other(let message, let context):
            let msg = "\(message)"
            return msg
        }
    }
}
