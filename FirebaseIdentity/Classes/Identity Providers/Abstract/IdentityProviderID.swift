//
//  IdentityProviderID.swift
//  AppController
//
//  Created by Christian Gossain on 2019-07-29.
//

import Foundation
import FirebaseAuth

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

extension IdentityProviderID: CaseIterable {
    public static var allCases: [IdentityProviderID] {
        return [.email, .facebook]
    }
    
    /// The Firebase provider ID for email authentication.
    public static let email = IdentityProviderID(rawValue: EmailAuthProviderID)!
    
    /// The Firebase provider ID for Facebook authentication.
    public static let facebook = IdentityProviderID(rawValue: FacebookAuthProviderID)!
}
