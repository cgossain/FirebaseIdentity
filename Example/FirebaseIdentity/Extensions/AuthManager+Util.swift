//
//  AuthManager+Util.swift
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

import Foundation
import FirebaseAuth
import FirebaseIdentity

extension AuthManager {
    static var debugEmailProviderUsers = [
        FUser(email: "test1@test.com", password: "password111"),
        FUser(email: "test2@test.com", password: "password111"),
        FUser(email: "test1@test.com", password: "password222"),
        FUser(email: "test2@test.com", password: "password222")
    ]
    
    static var debugPasswordUpdate = [
        PasswordUpdate(current: "password111", new: "password222"),
        PasswordUpdate(current: "password222", new: "password111")
    ]
    
    static var debugDisplayNameUpdate = [
        "Name 1",
        "Name 2",
        "Name 3"
    ]
}

extension AuthManager {
    var authenticatedUser: User? {
        guard case let .authenticated(user) = authState else {
            return nil
        }
        return user
    }
}
