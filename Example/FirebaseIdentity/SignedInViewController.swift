//
//  SignedInViewController.swift
//  Firebase Auth Test
//
//  Created by Christian Gossain on 2019-02-15.
//  Copyright © 2019 MooveFit Technologies Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseIdentity

class SignedInViewController: UIViewController {
    // MARK: - Lifecycle
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
        
        let signOutButton = UIButton(type: .system)
        signOutButton.setTitle("Sign Out", for: .normal)
        signOutButton.setTitleColor(.white, for: .normal)
        signOutButton.addTarget(self, action: #selector(SignedInViewController.signOutButtonTapped(_:)), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [signOutButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
    }
    
    @objc func signOutButtonTapped(_ sender: UIButton) {
        try! Auth.auth().signOut()
    }
    
}
