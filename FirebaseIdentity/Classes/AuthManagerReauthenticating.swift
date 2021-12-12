//
//  AuthManagerReauthenticating.swift
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

/// A protocol for an object that is capable of reauthenticating an AuthManager.
public protocol AuthManagerReauthenticating: AnyObject {
    /// Called when an action triggers the `requiresRecentLogin` from Firebase.
    ///
    /// - Parameters:
    ///     - manager: The auth manager instance that is requesting reauthentication.
    ///     - providers: An array of available/linked providers that should be used for reauthentication. These can either be presented as options to a user, or the
    ///                  first item in the list can automatically be used for reauthentication. The providers are pre-sorted according to the priority order specified in
    ///                  the `providerReauthenticationPriority` property of the AuthManager.
    ///     - challenge: An object that must be passed to the auth manager's `reauthenticate` method. This is required to continue/retry the action that triggered the `requiresRecentLogin` error.
    func authManager(_ manager: AuthManager, reauthenticateUsing providers: [IdentityProviderUserInfo], challenge: ProfileChangeReauthenticationChallenge)
}
