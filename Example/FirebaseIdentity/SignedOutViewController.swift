//
//  SignedOutViewController.swift
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

extension AuthManager {
    static var debugEmailProviderUsers: [FUser] = [FUser(email: "test@test.com", password: "password111"),
                                                   FUser(email: "cgossain@gmail.com", password: "password222")]
}

class SignedOutViewController: StaticTableViewController {
    // MARK: - Private Properties
    fileprivate let fbLoginManager = LoginManager()
    
    
    // MARK: - Lifecycle
    init() {
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Welcome", comment: "navigation bar title")
        reloadSections()
    }
    
}

fileprivate extension SignedOutViewController {
    func reloadSections() {
        // update data source
        let sections = [welcomeSection]
        dataSource.sections = sections
    }
    
    var welcomeSection: Section {
        var emailSignUpRow = Row(text: "Sign Up with Email", cellClass: Value1Cell.self)
        emailSignUpRow.selection = { [unowned self] in
            let alert = UIAlertController(title: "Select a User", message: nil, preferredStyle: .actionSheet)
            for user in AuthManager.debugEmailProviderUsers {
                alert.addAction(UIAlertAction(title: user.email, style: .default, handler: { (action) in
                    let provider = EmailIdentityProvider(email: user.email, password: user.password)
                    AuthManager.shared.signUp(with: provider) { (result) in
                        switch result {
                        case .success(let value):
                            print(value)
                            
                        case .failure(let error):
                            switch error {
                            case .requiresAccountLinking(let providerID, let context):
                                print("Requires account linking. \(providerID) \(context)")
                            case .invalidEmailOrPassword(let context):
                                print("Invalid email or password. \(context)")
                            case .emailBasedAccountAlreadyExists(let context):
                                print("An email account already exists with this email address. \(context)")
                            case .other(let message, let context):
                                print("\(message). \(context)")
                            }
                        }
                    }
                }))
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        var emailSignInRow = Row(text: "Sign In with Email", cellClass: Value1Cell.self)
        emailSignInRow.selection = { [unowned self] in
            let alert = UIAlertController(title: "Select a User", message: nil, preferredStyle: .actionSheet)
            for user in AuthManager.debugEmailProviderUsers {
                alert.addAction(UIAlertAction(title: user.email, style: .default, handler: { (action) in
                    let provider = EmailIdentityProvider(email: user.email, password: user.password)
                    AuthManager.shared.signIn(with: provider) { (result) in
                        switch result {
                        case .success(let value):
                            print(value)
                            
                        case .failure(let error):
                            switch error {
                            case .requiresAccountLinking(let providerID, let context):
                                print("Requires account linking. \(providerID) \(context)")
                            case .invalidEmailOrPassword(let context):
                                print("Invalid email or password. \(context)")
                            case .emailBasedAccountAlreadyExists(let context):
                                print("An email account already exists with this email address. \(context)")
                            case .other(let message, let context):
                                print("\(message). \(context)")
                            }
                        }
                    }
                }))
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        var emailSignInWrongPasswordRow = Row(text: "Sign In with Email (wrong password)", cellClass: Value1Cell.self)
        emailSignInWrongPasswordRow.selection = { [unowned self] in
            let alert = UIAlertController(title: "Select a User", message: nil, preferredStyle: .actionSheet)
            for user in AuthManager.debugEmailProviderUsers {
                alert.addAction(UIAlertAction(title: user.email, style: .default, handler: { (action) in
                    let provider = EmailIdentityProvider(email: user.email, password: "somewrongpasword")
                    AuthManager.shared.signIn(with: provider) { (result) in
                        switch result {
                        case .success(let value):
                            print(value)
                            
                        case .failure(let error):
                            switch error {
                            case .requiresAccountLinking(let providerID, let context):
                                print("Requires account linking. \(providerID) \(context)")
                            case .invalidEmailOrPassword(let context):
                                print("Invalid email or password. \(context)")
                            case .emailBasedAccountAlreadyExists(let context):
                                print("An email account already exists with this email address. \(context)")
                            case .other(let message, let context):
                                print("\(message). \(context)")
                            }
                        }
                    }
                }))
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        var fbSignUpInEmailNotSharedRow = Row(text: "Sign Up/In with Facebook (no email)", cellClass: Value1Cell.self)
        fbSignUpInEmailNotSharedRow.selection = { [unowned self] in
            let requestedPermissions: [String] = []
            self.fbLoginManager.logIn(permissions: requestedPermissions, from: self) { (result, error) in
                guard let result = result, !result.isCancelled else {
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    return
                }

                let token = AccessToken.current!.tokenString
                let provider = FaceboookIdentityProvider(accessToken: token)
                AuthManager.shared.signUp(with: provider) { (result) in
                    switch result {
                    case .success(let value):
                        print(value)
                        
                    case .failure(let error):
                        switch error {
                        case .requiresAccountLinking(let providerID, let context):
                            print("Requires account linking. \(providerID) \(context)")
                        case .invalidEmailOrPassword(let context):
                            print("Invalid email or password. \(context)")
                        case .emailBasedAccountAlreadyExists(let context):
                            print("An email account already exists with this email address. \(context)")
                        case .other(let message, let context):
                            print("\(message). \(context)")
                        }
                    }
                }
            }
        }
        
        var fbSignUpInEmailSharedRow = Row(text: "Sign Up/In with Facebook", cellClass: Value1Cell.self)
        fbSignUpInEmailSharedRow.selection = { [unowned self] in
            let requestedPermissions: [String] = ["email"]
            self.fbLoginManager.logIn(permissions: requestedPermissions, from: self) { (result, error) in
                guard let result = result, !result.isCancelled else {
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    return
                }
                
                let token = AccessToken.current!.tokenString
                let provider = FaceboookIdentityProvider(accessToken: token)
                AuthManager.shared.signUp(with: provider) { (result) in
                    switch result {
                    case .success(let value):
                        print(value)
                        
                    case .failure(let error):
                        switch error {
                        case .requiresAccountLinking(let providerID, let context):
                            print("Requires account linking. \(providerID) \(context)")
                        case .invalidEmailOrPassword(let context):
                            print("Invalid email or password. \(context)")
                        case .emailBasedAccountAlreadyExists(let context):
                            print("An email account already exists with this email address. \(context)")
                        case .other(let message, let context):
                            print("\(message). \(context)")
                        }
                    }
                }
            }
        }
        
        return Section(header: .title("Welcome. Please Sign Up/In"), rows: [emailSignUpRow, fbSignUpInEmailNotSharedRow, fbSignUpInEmailSharedRow, emailSignInRow, emailSignInWrongPasswordRow])
    }
    
}
