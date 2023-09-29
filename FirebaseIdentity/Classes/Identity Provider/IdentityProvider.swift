//
//  IdentityProvider.swift
//
//  Copyright (c) 2019-2021 Christian Gossain
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
import CryptoKit

public protocol IdentityProvider {
    /// The identity provider ID of the receiver.
    var providerID: IdentityProviderID { get }
    
    /// Starts the identity providers sign up routine.
    func signUp(completion: @escaping ((AuthDataResult?, Error?) -> Void))
    
    /// Starts the identity providers sign in routine.
    func signIn(completion: @escaping ((AuthDataResult?, Error?) -> Void))
    
    /// Reauthenticates the currently signed in user using the credentials specified by the receiver.
    func reauthenticate(completion: @escaping ((AuthDataResult?, Error?) -> Void))
    
    /// Links the currently signed in user with the credentials specified by the receiver.
    func link(completion: @escaping ((AuthDataResult?, Error?) -> Void))
}


@available(iOS 13.0, *)
extension IdentityProvider {
    /// Generates and returns a hashed version of the input string using the SHA256 algorithm.
    static public func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap { return String(format: "%02x", $0) }.joined()
      return hashString
    }
    
    /// Generates and returns a cryptographically randon nonce.
    ///
    /// Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    static public func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
}
