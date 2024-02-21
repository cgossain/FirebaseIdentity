//
//  FacebookIdentityProvider.swift
//
//  Copyright (c) 2024 Christian Gossain
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

import FirebaseAuth
import Foundation

/// The Facebook identity provider.
public final class FaceboookIdentityProvider: IdentityProviding {
    
    /// The identity provider ID.
    public let providerID: IdentityProviderID
    
    /// The facebook access token.
    public let accessToken: String
    
    // MARK: - Init
    
    /// Initializer.
    public init(accessToken: String) {
        self.providerID = .facebook
        self.accessToken = accessToken
    }
    
    // MARK: - IdentityProviding
    
    public func signUp(
        using auth: Auth,
        completion: @escaping ((AuthDataResult?, Error?) -> Void)
    ) {
        auth.signIn(
            with: credential,
            completion: completion
        )
    }
    
    public func signIn(
        using auth: Auth,
        completion: @escaping ((AuthDataResult?, Error?) -> Void)
    ) {
        auth.signIn(
            with: credential,
            completion: completion
        )
    }
    
    public func reauthenticate(
        using auth: Auth,
        completion: @escaping ((AuthDataResult?, Error?) -> Void)
    ) {
        guard let currentUser = auth.currentUser else {
            completion(nil, nil)
            return
        }
        
        currentUser
            .reauthenticate(
                with: credential,
                completion: completion
            )
    }
    
    public func link(
        using auth: Auth,
        completion: @escaping ((AuthDataResult?, Error?) -> Void)
    ) {
        guard let currentUser = auth.currentUser else {
            completion(nil, nil)
            return
        }
        
        currentUser
            .link(
                with: credential,
                completion: completion
            )
    }
    
    // MARK: - Private
    
    private var credential: AuthCredential {
        FacebookAuthProvider.credential(withAccessToken: accessToken)
    }
}
