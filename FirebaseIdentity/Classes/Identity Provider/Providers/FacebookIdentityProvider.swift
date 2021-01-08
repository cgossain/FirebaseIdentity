//
//  FacebookIdentityProvider.swift
//
//  Copyright (c) 2019-2020 Christian Gossain
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
    
    public func link(completion: @escaping AuthDataResultCallback) {
        if let currentUser = Auth.auth().currentUser {
            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken)
            currentUser.link(with: credential, completion: completion)
        }
        else {
            completion(nil, nil)
        }
    }
}
