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
        title = NSLocalizedString("Settings", comment: "navigation bar title")
        
        guard let authenticatedUser = AuthManager.shared.authenticatedUser else {
            return
        }
        
        print(authenticatedUser.debugDescription)
        reloadSections()
    }
    
}

fileprivate extension SignedInViewController {
    func reauthenticate(withCompletionHandler completionHandler: ((AuthDataResult?, Error?) -> Void)?) {
        guard let authenticatedUser = AuthManager.shared.authenticatedUser else {
            completionHandler?(nil, nil)
            return
        }
        
        fetchCredentialForReauthentication { (credential) in
            guard let credential = credential else {
                completionHandler?(nil, nil)
                return
            }
            authenticatedUser.reauthenticate(with: credential, completion: completionHandler)
        }
    }
    
    func fetchCredentialForReauthentication(withCompletionHandler completionHandler: ((AuthCredential?) -> Void)?) {
        guard let providerForReauthentication = AuthManager.shared.linkedProviders?.first else {
            completionHandler?(nil)
            return
        }
        
        switch providerForReauthentication {
        case .email:
            // FIXME: need to ask user to pick
            let user1 = AuthManager.debugEmailProviderUsers[0]
            let credential = EmailAuthProvider.credential(withEmail: user1.email, password: user1.password)
            completionHandler?(credential)
            
        case .facebook:
            if let token = AccessToken.current?.tokenString {
                let credential = FacebookAuthProvider.credential(withAccessToken: token)
                completionHandler?(credential)
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
                    let credential = FacebookAuthProvider.credential(withAccessToken: token)
                    completionHandler?(credential)
                }
            }
            
        default:
            completionHandler?(nil)
        }
    }
}

fileprivate extension SignedInViewController {
    func reloadSections() {
        // update data source
        let sections = [accountSection, linkedProvidersSection, signOutSection]
        dataSource.sections = sections
    }
    
    var accountSection: Section {
        var emailRow = Row(text: NSLocalizedString("Update Email", comment: "cell title"), cellClass: Value1Cell.self)
        emailRow.detailText = AuthManager.shared.authenticatedUser?.email ?? "none"
        emailRow.accessory = .disclosureIndicator
        emailRow.selection = { [unowned self] in
            let alert = UIAlertController(title: "Update Email", message: "Pick an email to use", preferredStyle: .actionSheet)
            // eliminate duplicate emails by converting the mapped array to a Set
            for email in Set(AuthManager.debugEmailProviderUsers.map({ $0.email })) {
                alert.addAction(UIAlertAction(title: email, style: .default, handler: { (action) in
                    self.reauthenticate(withCompletionHandler: { (result, error) in
                        if let error = error {
                            print(error)
                            self.showAlert(for: error)
                        }
                        else {
                            guard let authenticatedUser = AuthManager.shared.authenticatedUser else {
                                return
                            }
                            
                            authenticatedUser.updateEmail(to: email, completion: { (error) in
                                if let nsError = error as NSError? {
                                    print(nsError.code)
                                    print(nsError.domain)
                                    print(nsError.localizedDescription)
                                    print(error!.localizedDescription)
                                    self.showAlert(for: nsError)
                                }
                                else {
                                    print("Email Updated Successfully")
                                    self.reloadSections()
                                }
                            })
                        }
                    })
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        var passwordRow = Row(text: NSLocalizedString("Update Password", comment: "cell title"), cellClass: Value1Cell.self)
        passwordRow.accessory = .disclosureIndicator
        passwordRow.selection = { [unowned self] in
            let alert = UIAlertController(title: "Update Password", message: "Pick a password to use", preferredStyle: .actionSheet)
            // eliminate duplicate emails by converting the mapped array to a Set
            for password in Set(AuthManager.debugEmailProviderUsers.map({ $0.password })) {
                alert.addAction(UIAlertAction(title: password, style: .default, handler: { (action) in
                    self.reauthenticate(withCompletionHandler: { (result, error) in
                        if let error = error {
                            print(error)
                            self.showAlert(for: error)
                        }
                        else {
                            guard let authenticatedUser = AuthManager.shared.authenticatedUser else {
                                return
                            }
                            
                            authenticatedUser.updatePassword(to: password, completion: { (error) in
                                if let nsError = error as NSError? {
                                    print(nsError.code)
                                    print(nsError.domain)
                                    print(nsError.localizedDescription)
                                    print(error!.localizedDescription)
                                    self.showAlert(for: nsError)
                                }
                                else {
                                    print("Password Updated Successfully")
                                    self.reloadSections()
                                }
                            })
                        }
                    })
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        return Section(header: .title("Account"), rows: [emailRow, passwordRow])
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
        var signOutRow = Row(text: NSLocalizedString("Sign Out", comment: "cell title"), cellClass: Value1Cell.self)
        signOutRow.selection = {
            try! Auth.auth().signOut()
            LoginManager().logOut()
        }
        return Section(rows: [signOutRow])
    }
    
}
