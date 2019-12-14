//
//  IdentityProvider.swift
//  Firebase Identity
//
//  Created by Christian Gossain on 2019-02-19.
//  Copyright © 2019 MooveFit Technologies Inc. All rights reserved.
//

import Foundation
import FirebaseAuth

public protocol IdentityProvider {
    /// The provider ID of the receiver.
    var providerID: IdentityProviderID { get }
    
    /// Starts the identity providers sign up routine.
    func signUp(completion: @escaping AuthDataResultCallback)
    
    /// Starts the identity providers sign in routine.
    func signIn(completion: @escaping AuthDataResultCallback)
    
    /// Reauthenticates the currently signed in user using the credentials specified by the receiver.
    func reauthenticate(completion: @escaping AuthDataResultCallback)
    
    /// Links the currently signed in user with the credentials specified by the receiver.
    func link(completion: @escaping AuthDataResultCallback)
}
