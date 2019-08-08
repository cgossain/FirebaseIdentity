//
//  FacebookIdentityProvider.swift
//  Firebase Identity
//
//  Created by Christian Gossain on 2019-02-19.
//  Copyright © 2019 MooveFit Technologies Inc. All rights reserved.
//

import Foundation
import FirebaseAuth

public final class FaceboookIdentityProvider: IdentityProvider {    
    public let providerID: IdentityProviderID
    public let accessToken: String
    
    public init(accessToken: String) {
        self.providerID = .facebook
        self.accessToken = accessToken
    }
    
    public func signUp(completion: @escaping AuthDataResultCallback) {
        let credential = FacebookAuthProvider.credential(withAccessToken: accessToken)
        Auth.auth().signIn(with: credential, completion: completion)
    }
    
    public func signIn(completion: @escaping AuthDataResultCallback) {
        let credential = FacebookAuthProvider.credential(withAccessToken: accessToken)
        Auth.auth().signIn(with: credential, completion: completion)
    }
    
    public func reauthenticate(completion: @escaping AuthDataResultCallback) {
        if let currentUser = Auth.auth().currentUser {
            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken)
            currentUser.reauthenticate(with: credential, completion: completion)
        }
        else {
            completion(nil, nil)
        }
    }
}
