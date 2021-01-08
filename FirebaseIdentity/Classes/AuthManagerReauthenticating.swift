//
//  AuthManagerReauthenticating.swift
//  FirebaseIdentity
//
//  Created by Christian Gossain on 2021-01-08.
//

import Foundation

/// A protocol for an object that is capable of reauthenticating an AuthManager.
public protocol AuthManagerReauthenticating: class {
    /// Called when an action triggers the `requiresRecentLogin` from Firebase.
    ///
    /// - parameters:
    ///     - manager: The auth manager instance that is requesting reauthentication.
    ///     - providers: An array of available/linked providers that should be used for reauthentication. These can either be presented as options to a user, or the
    ///                  first item in the list can automatically be used for reauthentication. The providers are pre-sorted according to the priority order specified in
    ///                  the `providerReauthenticationPriority` property of the AuthManager.
    ///     - challenge: An object that must be passed to the auth manager's `reauthenticate` method. This is required to continue/retry the action that triggered the `requiresRecentLogin` error.
    func authManager(_ manager: AuthManager, reauthenticateUsing providers: [IdentityProviderUserInfo], challenge: ProfileChangeReauthenticationChallenge)
}
