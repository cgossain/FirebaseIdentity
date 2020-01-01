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

extension IdentityProviderID: CustomStringConvertible {
    public var description: String {
        switch self {
        case .email:
            return LocalizedString("Email", comment: "identity provider name")
        case .facebook:
            return LocalizedString("Facebook", comment: "identity provider name")
        default:
            return "undefined"
        }
    }
}

extension IdentityProviderID: Equatable, Hashable {
    public static func ==(lhs: IdentityProviderID, rhs: IdentityProviderID) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
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
