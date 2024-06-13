//
//  IdentityProviderID.swift
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

public struct IdentityProviderID: RawRepresentable {
    
    /// Initializes the type with a raw Firebase auth provider ID.
    public init?(rawValue: String) {
        if rawValue == FirebaseAuth.EmailAuthProviderID {
            self.rawValue = FirebaseAuth.EmailAuthProviderID
        }
        else if rawValue == SignInWithAppleAuthProviderID {
            self.rawValue = SignInWithAppleAuthProviderID
        }
        else if rawValue == FirebaseAuth.FacebookAuthProviderID {
            self.rawValue = FirebaseAuth.FacebookAuthProviderID
        }
        else {
            return nil
        }
    }
    
    /// The raw Firebase auth provider ID.
    public let rawValue: String
}

extension IdentityProviderID: CustomStringConvertible {
    public var description: String {
        switch self {
        case .email:
            return LocalizedString("Email", comment: "identity provider name")
        case .signInWithApple:
            return LocalizedString("Sign in with Apple", comment: "identity provider name")
        case .facebook:
            return LocalizedString("Facebook", comment: "identity provider name")
        default:
            return "undefined"
        }
    }
}

extension IdentityProviderID: Equatable {
    public static func ==(lhs: IdentityProviderID, rhs: IdentityProviderID) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension IdentityProviderID: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
