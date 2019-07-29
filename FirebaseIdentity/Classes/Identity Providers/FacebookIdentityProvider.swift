//
//  FacebookIdentityProvider.swift
//  Firebase Identity
//
//  Created by Christian Gossain on 2019-02-19.
//  Copyright © 2019 MooveFit Technologies Inc. All rights reserved.
//

import Foundation
import FirebaseAuth

public class FaceboookIdentityProvider: IdentityProvider {
    public let providerID: IdentityProviderID
    public let accessToken: String
    
    public init(accessToken: String) {
        self.providerID = .facebook
        self.accessToken = accessToken
    }
    
    public func signUp(completion: @escaping AuthDataResultCallback) {
        let credential = FacebookAuthProvider.credential(withAccessToken: accessToken)
        Auth.auth().signIn(with: credential) { (result, error) in
            completion(result, error)
        }
    }
    
    public func signIn(completion: @escaping AuthDataResultCallback) {
        let credential = FacebookAuthProvider.credential(withAccessToken: accessToken)
        Auth.auth().signIn(with: credential) { (result, error) in
            completion(result, error)
        }
    }
    
}
