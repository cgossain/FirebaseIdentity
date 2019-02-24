//
//  FacebookIdentityProvider.swift
//  Firebase Identity
//
//  Created by Christian Gossain on 2019-02-19.
//  Copyright © 2019 MooveFit Technologies Inc. All rights reserved.
//

import Foundation
import FirebaseAuth

class FaceboookIdentityProvider: IdentityProvider {
    let providerID: IdentityProviderID
    let accessToken: String
    
    init(accessToken: String) {
        self.providerID = .facebook
        self.accessToken = accessToken
    }
    
    func signUp(completion: @escaping AuthDataResultCallback) {
        let credential = FacebookAuthProvider.credential(withAccessToken: accessToken)
        Auth.auth().signInAndRetrieveData(with: credential) { (result, error) in
            completion(result, error)
        }
    }
    
    func signIn(completion: @escaping AuthDataResultCallback) {
        let credential = FacebookAuthProvider.credential(withAccessToken: accessToken)
        Auth.auth().signInAndRetrieveData(with: credential) { (result, error) in
            completion(result, error)
        }
    }
    
}
