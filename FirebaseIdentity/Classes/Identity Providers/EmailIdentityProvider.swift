//
//  EmailIdentityProvider.swift
//  Firebase Identity
//
//  Created by Christian Gossain on 2019-02-19.
//  Copyright © 2019 MooveFit Technologies Inc. All rights reserved.
//

import Foundation
import FirebaseAuth

public class EmailIdentityProvider: IdentityProvider {
    public let providerID: IdentityProviderID
    public let email: String
    public let password: String
    
    public init(email: String, password: String) {
        self.providerID = .email
        self.email = email
        self.password = password
    }
    
    public func signUp(completion: @escaping (AuthDataResult?, Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            completion(result, error)
        }
    }
    
    public func signIn(completion: @escaping (AuthDataResult?, Error?) -> Void) {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        Auth.auth().signIn(with: credential) { (result, error) in
            completion(result, error)
        }
    }
    
}
