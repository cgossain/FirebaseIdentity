//
//  SignedInViewController.swift
//  Firebase Auth Test
//
//  Created by Christian Gossain on 2019-02-15.
//  Copyright © 2019 MooveFit Technologies Inc. All rights reserved.
//

import UIKit
import Static
import Firebase
import FirebaseIdentity
import FBSDKLoginKit

class SignedInViewController: StaticTableViewController {
    // MARK: - Private Properties
    fileprivate let fbLoginManager = LoginManager()
    fileprivate let fbPermissions = ["email"]
    
    
    // MARK: - Lifecycle
    init() {
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        
        guard let authenticatedUser = AuthManager.shared.authenticatedUser else {
            return
        }
        
        print(authenticatedUser.debugDescription)
        
        AuthManager.shared.delegate = self
        
        reloadSections()
    }
    
}

extension SignedInViewController: AuthManagerDelegate {
    func authManager(_ manager: AuthManager, didReceive challenge: ProfileChangeReauthenticationChallenge) {
        // automatically ask for reauthentication via an email provider if available, otherwise fallback to another provider
        let prioritySequence = manager.linkedProviders.sorted { (lhs, rhs) -> Bool in return lhs.providerID == .email }
        
        // ask for reauthentication from the highest priority auth provider (email should be tried first if available)
        guard let provider = prioritySequence.first else {
            return
        }
        
        if provider.providerID == .email {
            // an email provider will always have an email associated with it, therefore it should be safe to force unwrap this value here;
            // what if there is some kind of error that causes the email to be non-existant in this scenario? Force the user to log-out, then back in?
            // it seems like it would be impossible for the email to not exist on an email auth provider
            let email = provider.email!
            
            // present UI for user to provider their current password
            let alert = UIAlertController(title: "Confirm Password", message: "Your current password is required to change your email address.\n\nCurrent Email: \(email)\nTarget Email:\(challenge.context.profileChangeType.attemptedValue)", preferredStyle: .actionSheet)
            for password in Set(AuthManager.debugEmailProviderUsers.map({ $0.password })) {
                alert.addAction(UIAlertAction(title: password, style: .default, handler: { (action) in
                    let provider = EmailIdentityProvider(email: email, password: password)
                    manager.reauthenticate(with: provider, for: challenge, errorHandler: { (error) in
                        self.showAuthenticationErrorAlert(for: error)
                    })
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else if provider.providerID == .facebook {
            fetchFacebookAccessTokenForReauthentication { (token) in
                guard let token = token else {
                    return
                }
                let provider = FaceboookIdentityProvider(accessToken: token)
                manager.reauthenticate(with: provider, for: challenge, errorHandler: { (error) in
                    self.showAuthenticationErrorAlert(for: error)
                })
            }
        }
    }
}

fileprivate extension SignedInViewController {
    func fetchFacebookAccessTokenForReauthentication(withCompletionHandler completionHandler: ((String?) -> Void)?) {
        if let token = AccessToken.current?.tokenString {
            completionHandler?(token)
        }
        else {
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
}

fileprivate extension SignedInViewController {
    func reloadSections() {
        let sections = [self.accountSection, self.linkedProvidersSection, self.signOutSection]
        self.dataSource.sections = sections
    }
    
    var accountSection: Section {
        let isEmailSet = AuthManager.shared.authenticatedUser?.email != nil
        
        var emailRow = Row(text: isEmailSet ? "Update Email" : "Set Email", cellClass: Value1Cell.self)
        emailRow.detailText = AuthManager.shared.authenticatedUser?.email ?? "none"
        emailRow.accessory = .disclosureIndicator
        emailRow.selection = { [unowned self] in
            let alert = UIAlertController(title: "Update Email", message: "Pick an email to use", preferredStyle: .actionSheet)
            // eliminate duplicate emails by converting the mapped array to a Set
            for email in Set(AuthManager.debugEmailProviderUsers.map({ $0.email })) {
                alert.addAction(UIAlertAction(title: email, style: .default, handler: { (action) in
                    AuthManager.shared.updateEmail(to: email, completion: { (result) in
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
        
        let isEmailProviderLinked = AuthManager.shared.linkedProviders.filter({ $0.providerID == .email }).first != nil
        
        var passwordRow = Row(text: isEmailProviderLinked ? "Update Password" : "Set Password", cellClass: Value1Cell.self)
        passwordRow.accessory = .disclosureIndicator
        passwordRow.selection = { [unowned self] in
            let alert = UIAlertController(title: "Update Password", message: "Pick a password to use", preferredStyle: .actionSheet)
            // eliminate duplicate emails by converting the mapped array to a Set
            for password in Set(AuthManager.debugEmailProviderUsers.map({ $0.password })) {
                alert.addAction(UIAlertAction(title: password, style: .default, handler: { (action) in
                    AuthManager.shared.updatePassword(to: password, completion: { (result) in
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
        
        let isFacebookProviderLinked = AuthManager.shared.linkedProviders.map({ $0.providerID }).contains(.facebook)
        let facebookEmail = AuthManager.shared.linkedProviders.filter({ $0.providerID == .facebook }).compactMap({ $0.email }).first
        
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
                        AuthManager.shared.linkWith(with: provider, completion: { (result) in
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
                // user must have at least 1 remaining auth provider after unlinking
                if AuthManager.shared.linkedProviders.filter({ $0.providerID != .facebook }).isEmpty {
                    // the user won't have a way to sign into their account if we proceed; user needs to set another auth method before proceeding
                    if let authenticatedUser = AuthManager.shared.authenticatedUser, authenticatedUser.email == nil {
                        self.showAlert(withTitle: "Add a Provider", message: "You need to set an email and password before unlinking your Facebook account.")
                    }
                    else {
                        self.showAlert(withTitle: "Add a Provider", message: "You need to set a password before unlinking your Facebook account.")
                    }
                    
                    self.reloadSections() // resets switch state
                }
                else {
                    // there are still other auth providers linked to the users account; it's safe to unlink
                    AuthManager.shared.unlinkFrom(providerID: .facebook, completion: { (result) in
                        switch result {
                        case .success(let user):
                            print("Facebook successfully unlinked from \(user.description)")
                            self.reloadSections()
                            
                        case .failure(let error):
                            self.showAlert(for: error)
                            self.reloadSections() // resets switch state
                        }
                    })
                }
            }
        })
        
        return Section(header: .title("Account"), rows: [emailRow, passwordRow, linkFacebookRow])
    }
    
    var linkedProvidersSection: Section {
        var rows: [Row] = []
        AuthManager.shared.authenticatedUser?.providerData.forEach({ (providerInfo) in
            var row = Row(text: "Provider ID - \(providerInfo.providerID)", cellClass: SubtitleCell.self)
            row.detailText = "UID: \(providerInfo.uid), Email: \(providerInfo.email ?? "none")"
            rows.append(row)
        })
        return Section(header: .title("Linked Providers"), rows: rows)
    }
    
    var signOutSection: Section {
        var signOutRow = Row(text: "Sign Out", cellClass: Value1Cell.self)
        signOutRow.selection = {
            try! Auth.auth().signOut()
            LoginManager().logOut()
        }
        return Section(rows: [signOutRow])
    }
    
}
