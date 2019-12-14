//
//  IdentityProviderID.swift
//  AppController
//
//  Created by Christian Gossain on 2019-07-29.
//

import Foundation
import FirebaseAuth

public extension IdentityProviderID {
    /// The Firebase provider ID for email authentication.
    static let email = IdentityProviderID(rawValue: EmailAuthProviderID)!
    
    /// The Firebase provider ID for Facebook authentication.
    static let facebook = IdentityProviderID(rawValue: FacebookAuthProviderID)!
}

public struct IdentityProviderID: RawRepresentable {
    /// The raw Firebase auth provider ID.
    public let rawValue: String
    
    /// Initializes the type with a raw Firebase auth provider ID.
    public init?(rawValue: String) {
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

extension IdentityProviderID: Hashable, Equatable {
    public var hashValue: Int { return rawValue.hashValue }
    
    public static func ==(lhs: IdentityProviderID, rhs: IdentityProviderID) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}
