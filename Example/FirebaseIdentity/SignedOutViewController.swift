//
//  SignedOutViewController.swift
//  Firebase Auth Test
//
//  Created by Christian Gossain on 2019-02-15.
//  Copyright © 2019 MooveFit Technologies Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseIdentity
import FBSDKLoginKit

class SignedOutViewController: UIViewController {
    fileprivate var user1: FUser = {
        let email = "cgossain@gmail.com"
        let password = "test123"
        let user = FUser(email: email, password: password)
        return user
    }()
    
    fileprivate var user1WrongPass: FUser = {
        let email = "cgossain@gmail.com"
        let password = "wrongpass"
        let user = FUser(email: email, password: password)
        return user
    }()
    
    
    // MARK: - Lifecycle
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        
        let signIn1Button = UIButton(type: .system)
        signIn1Button.setTitle("Sign In User 1", for: .normal)
        signIn1Button.setTitleColor(.white, for: .normal)
        signIn1Button.addTarget(self, action: #selector(SignedOutViewController.signIn1ButtonTapped(_:)), for: .touchUpInside)
        
        let signIn1WrongButton = UIButton(type: .system)
        signIn1WrongButton.setTitle("Sign In User 1 Wrong Pass", for: .normal)
        signIn1WrongButton.setTitleColor(.white, for: .normal)
        signIn1WrongButton.addTarget(self, action: #selector(SignedOutViewController.signIn1WrongButtonTapped(_:)), for: .touchUpInside)
        
        let signUp1Button = UIButton(type: .system)
        signUp1Button.setTitle("Sign Up User 1", for: .normal)
        signUp1Button.setTitleColor(.white, for: .normal)
        signUp1Button.addTarget(self, action: #selector(SignedOutViewController.signUp1ButtonTapped(_:)), for: .touchUpInside)
        
        let facebookLoginButton = FBSDKLoginButton()
        facebookLoginButton.delegate = self
        facebookLoginButton.readPermissions = ["email"]
        
        let stackView = UIStackView(arrangedSubviews: [signIn1Button, signIn1WrongButton, signUp1Button, facebookLoginButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
    }
    
    @objc func signIn1ButtonTapped(_ sender: UIButton) {
        let provider = EmailIdentityProvider(email: user1.email, password: user1.password)
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
    }
    
    @objc func signIn1WrongButtonTapped(_ sender: UIButton) {
        let provider = EmailIdentityProvider(email: user1WrongPass.email, password: user1WrongPass.password)
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
    }
    
    @objc func signUp1ButtonTapped(_ sender: UIButton) {
        let provider = EmailIdentityProvider(email: user1.email, password: user1.password)
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

extension SignedOutViewController: FBSDKLoginButtonDelegate{
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        // continue if not cancelled
        if !result.isCancelled {
            let accessToken = FBSDKAccessToken.current().tokenString!
            let provider = FaceboookIdentityProvider(accessToken: accessToken)
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
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        
    }
}
