//
//  IdentityProvider.swift
//  Firebase Identity
//
//  Created by Christian Gossain on 2019-02-19.
//  Copyright © 2019 MooveFit Technologies Inc. All rights reserved.
//

import Foundation
import FirebaseAuth

protocol IdentityProvider {
    /// The provider ID of the receiver.
    var providerID: IdentityProviderID { get }
    
    /// Starts the identity providers sign up routine.
    func signUp(completion: @escaping AuthDataResultCallback)
    
    /// Starts the identity providers sign in routine.
    func signIn(completion: @escaping AuthDataResultCallback)
}

struct IdentityProviderID: RawRepresentable {
    /// The raw Firebase auth provider ID.
    let rawValue: String
    
    /// Initializes the type with a raw Firebase auth provider ID.
    init?(rawValue: String) {
        if rawValue == EmailAuthProviderID {
            self.rawValue = EmailAuthProviderID
        }
        else if rawValue == FacebookAuthProviderID {
            self.rawValue = FacebookAuthProviderID
        }
        else {
            return nil
        }
    }
}

extension IdentityProviderID {
    /// The Firebase provider ID for email authentication.
    static let email = IdentityProviderID(rawValue: EmailAuthProviderID)!
    
    /// The Firebase provider ID for Facebook authentication.
    static let facebook = IdentityProviderID(rawValue: FacebookAuthProviderID)!
}

extension IdentityProviderID: Hashable, Equatable {
    var hashValue: Int { return rawValue.hashValue }
    
    static func ==(lhs: IdentityProviderID, rhs: IdentityProviderID) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}
