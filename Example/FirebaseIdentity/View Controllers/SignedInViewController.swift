//
//  SignedInViewController.swift
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

import FBSDKLoginKit
import Firebase
import FirebaseIdentity
import Static
import UIKit

final class SignedInViewController: TableViewController {
    
    // MARK: - Init
    
    init() {
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        
        AuthManager
            .default
            .reauthenticator = self
        
        reloadSections()
    }
    
    // MARK: - Helpers
    
    private func reloadSections() {
        dataSource.sections = [
            accountSection,
            linkedProvidersSection,
            signOutSection, 
            deleteAccountSection
        ]
    }
    
    private func fetchFacebookAccessTokenForReauthentication(withCompletionHandler completionHandler: ((String?) -> Void)?) {
        if let token = AccessToken.current?.tokenString {
            completionHandler?(token)
        } else {
            fbLoginManager.logIn(permissions: fbPermissions, from: self) { (result, error) in
                guard let result = result, !result.isCancelled else {
                    if let error = error {
                        print(error)
                        self.showAlert(for: error)
                    }
                    completionHandler?(nil)
                    return
                }
                
                let token = AccessToken.current!.tokenString
                completionHandler?(token)
            }
        }
    }
    
    // MARK: - Private
    
    private let fbLoginManager = LoginManager()
    private let fbPermissions = ["email"]
}

extension SignedInViewController: AuthManagerReauthenticating {
    func authManager(_ manager: AuthManager, reauthenticateUsing providers: [AuthManager.IdentityProviderUserInfo], challenge: ProfileChangeReauthenticationChallenge) {
        // ask for reauthentication from the highest priority auth provider
        guard let provider = providers.first else {
            return
        }
        
        switch provider.providerID {
        case .email:
            // an email provider will always have an email associated with it, therefore it should be safe to force unwrap this value here;
            // what if there is some kind of error that causes the email to be non-existant in this scenario? Force the user to log-out, then back in?
            // it seems like it would be impossible for the email to not exist on an email auth provider
            let email = provider.email!
            
            // present UI for user to provider their current password
            let alert = UIAlertController(title: "Confirm Password", message: "Your current password is required to change your email address.\n\nCurrent Email: \(email)\nTarget Email:\(challenge.context.profileChangeType.attemptedValue)", preferredStyle: .actionSheet)
            for password in Set(AuthManager.debugEmailProviderUsers.map({ $0.password })) {
                alert.addAction(UIAlertAction(title: password, style: .default, handler: { (action) in
                    let provider = EmailIdentityProvider(email: email, password: password)
                    manager.reauthenticate(with: provider, challenge: challenge) { result in
                        switch result {
                        case .success(let value):
                            print(value)
                            
                        case .failure(let error):
                            self.showAuthenticationErrorAlert(for: error)
                        }
                    }
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        case .facebook:
            fetchFacebookAccessTokenForReauthentication { (token) in
                guard let token = token else {
                    return
                }
                let provider = FaceboookIdentityProvider(accessToken: token)
                manager.reauthenticate(with: provider, challenge: challenge) { result in
                    switch result {
                    case .success(let value):
                        print(value)
                        
                    case .failure(let error):
                        self.showAuthenticationErrorAlert(for: error)
                    }
                }
            }
        default:
            print("undefined provider")
        }
    }
}

fileprivate extension SignedInViewController {
    var accountSection: Section {
        var displayNameRow = Row(text: "Update Display Name", cellClass: Value1Cell.self)
        displayNameRow.detailText = AuthManager.default.authenticatedUser?.displayName ?? "n/a"
        displayNameRow.accessory = .disclosureIndicator
        displayNameRow.selection = { [unowned self] in
            let alert = UIAlertController(title: "Update Display Name", message: "Pick a display name to use", preferredStyle: .actionSheet)
            for name in AuthManager.debugDisplayNameUpdate {
                alert.addAction(UIAlertAction(title: name, style: .default, handler: { (action) in
                    AuthManager.default.updateDisplayName(to: name) { (result) in
                        switch result {
                        case .success(let value):
                            DispatchQueue.main.async {
                                print("Display Name Updated Successfully: \(value)")
                                self.reloadSections()
                            }
                        case .failure(let error):
                            self.showProfileChangeErrorAlert(for: error)
                        }
                    }
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        let isEmailSet = AuthManager.default.authenticatedUser?.email != nil
        var emailRow = Row(text: isEmailSet ? "Update Email" : "Set Email", cellClass: Value1Cell.self)
        emailRow.detailText = AuthManager.default.authenticatedUser?.email ?? "n/a"
        emailRow.accessory = .disclosureIndicator
        emailRow.selection = { [unowned self] in
            let alert = UIAlertController(title: "Update Email", message: "Pick an email to use", preferredStyle: .actionSheet)
            // eliminate duplicate emails by converting the mapped array to a Set
            for email in Set(AuthManager.debugEmailProviderUsers.map({ $0.email })) {
                alert.addAction(UIAlertAction(title: email, style: .default, handler: { (action) in
                    AuthManager.default.updateEmail(to: email, completion: { (result) in
                        switch result {
                        case .success(let value):
                            DispatchQueue.main.async {
                                print("Email Updated Successfully: \(value)")
                                self.reloadSections()
                            }
                            
                        case .failure(let error):
                            self.showProfileChangeErrorAlert(for: error)
                        }
                    })
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        var emailSilentReauthRow = Row(text: isEmailSet ? "Update Email (Silent)" : "Set Email (Silent)", cellClass: Value1Cell.self)
        emailSilentReauthRow.detailText = AuthManager.default.authenticatedUser?.email ?? "n/a"
        emailSilentReauthRow.accessory = .disclosureIndicator
        emailSilentReauthRow.selection = { [unowned self] in
            let alert = UIAlertController(title: "Update Email", message: "Pick an email to use", preferredStyle: .actionSheet)
            for user in AuthManager.debugEmailProviderUsers {
                alert.addAction(UIAlertAction(title: user.email+"/"+user.password, style: .default, handler: { (action) in
                    AuthManager.default.updateEmail(to: user.email, passwordForReauthentication: user.password, completion: { (result) in
                        switch result {
                        case .success(let value):
                            DispatchQueue.main.async {
                                print("Email Updated Successfully: \(value)")
                                self.reloadSections()
                            }
                            
                        case .failure(let error):
                            self.showProfileChangeErrorAlert(for: error)
                        }
                    })
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        let isEmailProviderLinked = AuthManager.default.linkedProviders.map({ $0.providerID }).contains(.email)
        var passwordRow = Row(text: isEmailProviderLinked ? "Update Password" : "Set Password", cellClass: Value1Cell.self)
        passwordRow.accessory = .disclosureIndicator
        passwordRow.selection = { [unowned self] in
            let alert = UIAlertController(title: "Update Password", message: "Pick a password to use", preferredStyle: .actionSheet)
            for passwordUpdate in AuthManager.debugPasswordUpdate {
                alert.addAction(UIAlertAction(title: passwordUpdate.new, style: .default, handler: { (action) in
                    AuthManager.default.updatePassword(to: passwordUpdate.new, completion: { (result) in
                        switch result {
                        case .success(let value):
                            DispatchQueue.main.async {
                                print("Password Updated Successfully: \(value)")
                                self.reloadSections()
                            }
                            
                        case .failure(let error):
                            self.showProfileChangeErrorAlert(for: error)
                        }
                    })
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        var passwordSilentReauthRow = Row(text: isEmailProviderLinked ? "Update Password (Silent)" : "Set Password (Silent)", cellClass: Value1Cell.self)
        passwordSilentReauthRow.accessory = .disclosureIndicator
        passwordSilentReauthRow.selection = { [unowned self] in
            let alert = UIAlertController(title: "Update Password", message: "Pick a password to use", preferredStyle: .actionSheet)
            for passwordUpdate in AuthManager.debugPasswordUpdate {
                alert.addAction(UIAlertAction(title: passwordUpdate.current+"/"+passwordUpdate.new, style: .default, handler: { (action) in
                    AuthManager.default.updatePassword(to: passwordUpdate.new, passwordForReauthentication: passwordUpdate.current, completion: { (result) in
                        switch result {
                        case .success(let value):
                            DispatchQueue.main.async {
                                print("Password Updated Successfully: \(value)")
                                self.reloadSections()
                            }
                            
                        case .failure(let error):
                            self.showProfileChangeErrorAlert(for: error)
                        }
                    })
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        let isFacebookProviderLinked = AuthManager.default.linkedProviders.map({ $0.providerID }).contains(.facebook)
        let facebookEmail = AuthManager.default.linkedProviders.filter({ $0.providerID == .facebook }).compactMap({ $0.email }).first
        var linkFacebookRow = Row(text: "Facebook", cellClass: SubtitleCell.self)
        linkFacebookRow.detailText = facebookEmail
        linkFacebookRow.accessory = .switchToggle(value: isFacebookProviderLinked, { [unowned self] (isOn) in
            if isOn {
                // link to facebook
                // 1. get an access token
                // 2. link
                self.fetchFacebookAccessTokenForReauthentication(withCompletionHandler: { (token) in
                    if let token = token {
                        let provider = FaceboookIdentityProvider(accessToken: token)
                        AuthManager.default.linkWith(with: provider, completion: { (result) in
                            switch result {
                            case .success(let authDataResult):
                                print("Facebook successfully linked with \(authDataResult.user.description)")
                                self.reloadSections()
                                
                            case .failure(let error):
                                self.showAuthenticationErrorAlert(for: error)
                                self.reloadSections() // resets switch state
                            }
                        })
                    }
                })
            }
            else {
                AuthManager.default.unlinkFrom(providerID: .facebook, completion: { (result) in
                    switch result {
                    case .success(let user):
                        print("Facebook successfully unlinked from \(user.description)")
                        self.reloadSections()
                        
                    case .failure(let error):
                        self.showProfileChangeErrorAlert(for: error)
                        self.reloadSections() // resets switch state
                    }
                })
                
//                // user must have at least 1 remaining auth provider after unlinking
//                if AuthManager.shared.linkedProviders.filter({ $0.providerID != .facebook }).isEmpty {
//                    // the user won't have a way to sign into their account if we proceed; user needs to set another auth method before proceeding
//                    if let authenticatedUser = AuthManager.shared.authenticatedUser, authenticatedUser.email == nil {
//                        self.showAlert(withTitle: "Add a Provider", message: "You need to set an email and password before unlinking your Facebook account.")
//                    }
//                    else {
//                        self.showAlert(withTitle: "Add a Provider", message: "You need to set a password before unlinking your Facebook account.")
//                    }
//
//                    self.reloadSections() // resets switch state
//                }
//                else {
//                    // there are still other auth providers linked to the users account; it's safe to unlink
//                    AuthManager.shared.unlinkFrom(providerID: .facebook, completion: { (result) in
//                        switch result {
//                        case .success(let user):
//                            print("Facebook successfully unlinked from \(user.description)")
//                            self.reloadSections()
//
//                        case .failure(let error):
//                            self.showAlert(for: error)
//                            self.reloadSections() // resets switch state
//                        }
//                    })
//                }
            }
        })
        
//        let email = AuthManager.shared.linkedProviders.filter({ $0.providerID == .email }).compactMap({ $0.email }).first
//        var linkEmailRow = Row(text: "Email", cellClass: SubtitleCell.self)
//        linkEmailRow.detailText = email
//        linkEmailRow.accessory = .switchToggle(value: isEmailProviderLinked, { [unowned self] (isOn) in
//            if isOn {
//                // link to facebook
//                // 1. get an access token
//                // 2. link
//                self.fetchFacebookAccessTokenForReauthentication(withCompletionHandler: { (token) in
//                    if let token = token {
//                        let provider = FaceboookIdentityProvider(accessToken: token)
//                        AuthManager.shared.linkWith(with: provider, completion: { (result) in
//                            switch result {
//                            case .success(let authDataResult):
//                                print("Facebook successfully linked with \(authDataResult.user.description)")
//                                self.reloadSections()
//
//                            case .failure(let error):
//                                self.showAuthenticationErrorAlert(for: error)
//                                self.reloadSections() // resets switch state
//                            }
//                        })
//                    }
//                })
//            }
//            else {
//                AuthManager.shared.unlinkFrom(providerID: .facebook, completion: { (result) in
//                    switch result {
//                    case .success(let user):
//                        print("Facebook successfully unlinked from \(user.description)")
//                        self.reloadSections()
//
//                    case .failure(let error):
//                        self.showAlert(for: error)
//                        self.reloadSections() // resets switch state
//                    }
//                })
//            }
//        })
        
        return Section(
            header: .title("Account"),
            rows: [
                displayNameRow,
                emailRow,
                emailSilentReauthRow,
                passwordRow,
                passwordSilentReauthRow,
                linkFacebookRow
            ]
        )
    }
    
    var linkedProvidersSection: Section {
        var rows: [Row] = []
        AuthManager.default.linkedProviders
            .forEach { providerInfo in
                var row = Row(text: "Provider ID - \(providerInfo.providerID)", cellClass: SubtitleCell.self)
                row.detailText = "UID: \(providerInfo.uid), Email: \(providerInfo.email ?? "n/a"), Display Name: \(providerInfo.displayName ?? "n/a")"
                rows.append(row)
            }
        
//        AuthManager.default.authenticatedUser?.providerData.forEach({ (providerInfo) in
//            var row = Row(text: "Provider ID - \(providerInfo.providerID)", cellClass: SubtitleCell.self)
//            row.detailText = "UID: \(providerInfo.uid), Email: \(providerInfo.email ?? "n/a"), Display Name: \(providerInfo.displayName ?? "n/a")"
//            rows.append(row)
//        })
        
        return Section(header: .title("Linked Providers"), rows: rows)
    }
    
    var signOutSection: Section {
        var signOutRow = Row(text: "Sign Out", cellClass: Value1Cell.self)
        signOutRow.selection = {
            AuthManager.default
                .signOut()
            
            LoginManager().logOut()
        }
        return Section(rows: [signOutRow])
    }
    
    var deleteAccountSection: Section {
        var deleteAccountRow = Row(text: "Delete Account", cellClass: Value1Cell.self)
        deleteAccountRow.selection = {
            AuthManager.default
                .deleteAccount { (result) in
                    switch result {
                    case .success(let user):
                        print("User Deleted Duccessfully: \(user)")
                        
                    case .failure(let error):
                        self.showProfileChangeErrorAlert(for: error)
                    }
                }
        }
        return Section(rows: [deleteAccountRow])
    }
}
