//
//  ProfileChangeReauthenticationChallenge.swift
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

/// An object that provides context about the profile change that triggered the reauthentication challenge.
public struct ProfileChangeReauthenticationChallenge {
    // MARK: - Public Properties
    /// A unique identifier for the challenge.
    public let uuid = UUID().uuidString
    
    /// The profile change context information allows the action that triggered reauthentication to be retried automatically if needed.
    public let context: ProfileChangeError.Context
    
    
    // MARK: - Internal Properties
    /// Interal use completion handler.
    let completion: AuthManager.ProfileChangeHandler
}

extension ProfileChangeReauthenticationChallenge: Equatable, Hashable {
    public static func == (lhs: ProfileChangeReauthenticationChallenge, rhs: ProfileChangeReauthenticationChallenge) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}
