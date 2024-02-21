//
//  SignInWithAppleIdentityProvider.swift
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

import AuthenticationServices
import FirebaseAuth
import Foundation

/// The error thrown when authentication with the Sign in with Apple identity provider fails.
public enum SignInWithAppleIdentityProviderError: Error {
    case unableToFetchIdentityToken
    case unableToSerializeIdentityToken
}

/// The Sign in with Apple identity provider.
@available(iOS 13.0, *)
public final class SignInWithAppleIdentityProvider: IdentityProviding {
    
    /// The identity provider ID of the receiver.
    public let providerID: IdentityProviderID
    
    /// The Apple ID credential from Apple's response.
    public let appleIDCredential: ASAuthorizationAppleIDCredential
    
    /// The nonce that was passed to Apple.
    public let nonce: String?
    
    /// The JSON Web Token (JWT) serialized from the ASAuthorizationAppleIDCredential.
    public let identityToken: String
    
    // MARK: - Init
    
    /// Initializes a "Sign in with Apple" identity provider.
    ///
    /// - Parameters:
    ///     - appleIDCredential: The credential returned by the AuthenticationServices framework.
    ///     - nonce: The nonce.
    /// - Throws: A SignInWithAppleIdentityProviderError error that explains why the initialization failed.
    public init(
        appleIDCredential: ASAuthorizationAppleIDCredential,
        nonce: String?
    ) throws {
        guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetch identity token")
            throw SignInWithAppleIdentityProviderError.unableToFetchIdentityToken
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            throw SignInWithAppleIdentityProviderError.unableToSerializeIdentityToken
        }
        
        self.providerID = .signInWithApple
        self.appleIDCredential = appleIDCredential
        self.nonce = nonce
        self.identityToken = idTokenString
    }
    
    // MARK: - IdentityProviding
    
    public func signUp(
        using auth: Auth,
        completion: @escaping ((AuthDataResult?, Error?) -> Void)
    ) {
        // the implementation of "sign up" is identical to "sign in"
        signIn(
            using: auth,
            completion: completion
        )
    }
    
    public func signIn(
        using auth: Auth,
        completion: @escaping ((AuthDataResult?, Error?) -> Void)
    ) {
        var appleIDDisplayName = ""
        if let fullName = appleIDCredential.fullName {
            let formatter = PersonNameComponentsFormatter()
            let displayName = formatter.string(from: fullName)
            appleIDDisplayName = displayName
        }
        
        auth.signIn(with: credential) { (result, error) in
            if let error = error {
                completion(result, error)
            }
            else {
                // if the signed in Firebase user does not have a display name but
                // one was shared via Sign in with Apple, let do a quick profile
                // change request to update it behind the scenes (since Firebase does
                // not automatically pick up the display name apparently)
                guard let authenticatedUser = result?.user, authenticatedUser.displayName == nil, !appleIDDisplayName.isEmpty else {
                    completion(result, error)
                    return
                }
                
                let profileChangeRequest = authenticatedUser.createProfileChangeRequest()
                profileChangeRequest.displayName = appleIDDisplayName
                profileChangeRequest.commitChanges { (_) in
                    // we can ignore any profile change errors since the point of
                    // this method is to authenticate successfully which we've done
                    completion(result, error)
                }
            }
        }
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
    
    private var credential: OAuthCredential {
        OAuthProvider
            .credential(
                withProviderID: providerID.rawValue,
                idToken: identityToken,
                rawNonce: nonce
            )
    }
}
