//
//  EmailIdentityProvider.swift
//  Firebase Identity
//
//  Created by Christian Gossain on 2019-02-19.
//  Copyright © 2019 MooveFit Technologies Inc. All rights reserved.
//

import Foundation
import FirebaseAuth

public final class EmailIdentityProvider: IdentityProvider {
    public let providerID: IdentityProviderID
    public let email: String
    public let password: String
    
    public init(email: String, password: String) {
        self.providerID = .email
        self.email = email
        self.password = password
    }
    
    public func signUp(completion: @escaping AuthDataResultCallback) {
        Auth.auth().createUser(withEmail: email, password: password, completion: completion)
    }
    
    public func signIn(completion: @escaping AuthDataResultCallback) {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        Auth.auth().signIn(with: credential, completion: completion)
    }
    
    public func reauthenticate(completion: @escaping AuthDataResultCallback) {
        if let currentUser = Auth.auth().currentUser {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            currentUser.reauthenticate(with: credential, completion: completion)
        }
        else {
            completion(nil, nil)
        }
    }
}
