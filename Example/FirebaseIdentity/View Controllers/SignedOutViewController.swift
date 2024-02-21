//
//  SignedOutViewController.swift
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

final class SignedOutViewController: TableViewController {
    
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
        title = "Welcome"
        reloadSections()
    }
    
    // MARK: - Helpers
    
    private func reloadSections() {
        // update data source
        let sections = [welcomeSection]
        dataSource.sections = sections
    }
    
    private var welcomeSection: Section {
        var emailSignUpRow = Row(text: "Sign Up with Email", cellClass: Value1Cell.self)
        emailSignUpRow.selection = { [unowned self] in
            let alert = UIAlertController(title: "Select a User", message: nil, preferredStyle: .actionSheet)
            for user in AuthManager.debugEmailProviderUsers {
                alert.addAction(UIAlertAction(title: user.email+"/"+user.password, style: .default, handler: { (action) in
                    let provider = EmailIdentityProvider(email: user.email, password: user.password)
                    AuthManager.default.signUp(with: provider) { (result) in
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
        }
        
        var emailSignInRow = Row(text: "Sign In with Email", cellClass: Value1Cell.self)
        emailSignInRow.selection = { [unowned self] in
            let alert = UIAlertController(title: "Select a User", message: nil, preferredStyle: .actionSheet)
            for user in AuthManager.debugEmailProviderUsers {
                alert.addAction(UIAlertAction(title: user.email+"/"+user.password, style: .default, handler: { (action) in
                    let provider = EmailIdentityProvider(email: user.email, password: user.password)
                    AuthManager.default.signIn(with: provider) { (result) in
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
        }
        
        var fbSignUpInEmailNotSharedRow = Row(text: "Sign Up/In with Facebook (no email)", cellClass: Value1Cell.self)
        fbSignUpInEmailNotSharedRow.selection = { [unowned self] in
            let requestedPermissions: [String] = []
            
            self.fbLoginManager.logIn(permissions: requestedPermissions, from: self) { (result, error) in
                guard let result = result, !result.isCancelled else {
                    if let error = error {
                        print(error.localizedDescription)
                        self.showAlert(for: error)
                    }
                    return
                }
                
                let token = AccessToken.current!.tokenString
                let provider = FaceboookIdentityProvider(accessToken: token)
                AuthManager.default.signUp(with: provider) { (result) in
                    switch result {
                    case .success(let value):
                        print(value)
                        
                    case .failure(let error):
                        self.showAuthenticationErrorAlert(for: error)
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
                        self.showAlert(for: error)
                    }
                    return
                }
                
                let token = AccessToken.current!.tokenString
                let provider = FaceboookIdentityProvider(accessToken: token)
                AuthManager.default.signUp(with: provider) { (result) in
                    switch result {
                    case .success(let value):
                        print(value)
                        
                    case .failure(let error):
                        self.showAuthenticationErrorAlert(for: error)
                    }
                }
            }
        }
        
        return Section(header: .title("Welcome. Please Sign Up/In"), rows: [emailSignUpRow, fbSignUpInEmailNotSharedRow, fbSignUpInEmailSharedRow, emailSignInRow])
    }
    
    // MARK: - Private
    
    private let fbLoginManager = LoginManager()
}
