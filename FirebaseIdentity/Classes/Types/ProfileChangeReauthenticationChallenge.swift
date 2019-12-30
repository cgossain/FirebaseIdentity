//
//  ProfileChangeReauthenticationChallenge.swift
//  Pods
//
//  Created by Christian Gossain on 2019-12-24.
//

import Foundation

/// An object that provides context about the profile change that triggered the reauthentication challenge.
public struct ProfileChangeReauthenticationChallenge {
    // MARK: - Public Properties
    /// A unique identifier for the challenge.
    public let uuid = UUID().uuidString
    
    /// The profile change context information allows the action that triggered reauthentication to be retried automatically if needed.
    public let context: ProfileChangeError.Context
    
    
    // MARK: - Internal Properties
    /// Interal use completion handler.
    let completion: ProfileChangeHandler
}

extension ProfileChangeReauthenticationChallenge: Equatable, Hashable {
    public static func == (lhs: ProfileChangeReauthenticationChallenge, rhs: ProfileChangeReauthenticationChallenge) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}
