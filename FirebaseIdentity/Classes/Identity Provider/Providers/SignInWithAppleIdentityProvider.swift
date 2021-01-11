//
//  SignInWithAppleIdentityProvider.swift
//  FirebaseIdentity
//
//  Created by Christian Gossain on 2021-01-08.
//

import Foundation
import AuthenticationServices
import CryptoKit
import FirebaseAuth

public enum SignInWithAppleIdentityProviderError: Error {
    case unableToFetchIdentityToken
    case unableToSerializeIdentityToken
}

@available(iOS 13.0, *)
public final class SignInWithAppleIdentityProvider: IdentityProvider {
    /// The Apple ID credential from Apple's response.
    public let appleIDCredential: ASAuthorizationAppleIDCredential
    
    /// The nonce that was passed to Apple.
    public let nonce: String?
    
    /// The JSON Web Token (JWT) serialized from the ASAuthorizationAppleIDCredential.
    public let identityToken: String
    
    /// The identity provider ID.
    public let providerID: IdentityProviderID
    
    
    // MARK: - Lifecycle
    /// Initializes a "Sign in with Apple" identity provider.
    ///
    /// - Throws: An SignInWithAppleIdentityProviderError error that explains why the initialization failed.
    public init(appleIDCredential: ASAuthorizationAppleIDCredential, nonce: String?) throws {
        guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetch identity token")
            throw SignInWithAppleIdentityProviderError.unableToFetchIdentityToken
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            throw SignInWithAppleIdentityProviderError.unableToSerializeIdentityToken
        }
        
        self.identityToken = idTokenString
        self.appleIDCredential = appleIDCredential
        self.nonce = nonce
        self.providerID = .signInWithApple
    }
    
    
    // MARK: - IdentityProvider
    public func signUp(completion: @escaping AuthDataResultCallback) {
        // the implementation of "sign up" is identical to "sign in"
        self.signIn(completion: completion)
    }
    
    public func signIn(completion: @escaping AuthDataResultCallback) {
        let credential = OAuthProvider.credential(withProviderID: providerID.rawValue,
                                                  idToken: identityToken,
                                                  rawNonce: nonce)
        
        var appleIDDisplayName = ""
        if let fullName = appleIDCredential.fullName {
            let formatter = PersonNameComponentsFormatter()
            let displayName = formatter.string(from: fullName)
            appleIDDisplayName = displayName
        }
        
        Auth.auth().signIn(with: credential) { (result, error) in
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
    
    public func reauthenticate(completion: @escaping AuthDataResultCallback) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(nil, nil)
            return
        }
        
        let credential = OAuthProvider.credential(withProviderID: providerID.rawValue,
                                                  idToken: identityToken,
                                                  rawNonce: nonce)
        
        currentUser.reauthenticate(with: credential, completion: completion)
    }
    
    public func link(completion: @escaping AuthDataResultCallback) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(nil, nil)
            return
        }
        
        let credential = OAuthProvider.credential(withProviderID: providerID.rawValue,
                                                  idToken: identityToken,
                                                  rawNonce: nonce)
        
        currentUser.link(with: credential, completion: completion)
    }
}

@available(iOS 13.0, *)
extension SignInWithAppleIdentityProvider {
    static public func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
      }.joined()

      return hashString
    }
    
    /// Generates and returns a cryptographically randon nonce.
    ///
    /// Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    static public func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
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
