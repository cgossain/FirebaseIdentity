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

class SignedInViewController: StaticTableViewController {
    var account: FAccount? {
        didSet {
            reloadSections()
        }
    }
    
    
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
    func reloadSections() {
        let sections = [accountSection, signOutSection]
        dataSource.sections = sections
    }
    
    var accountSection: Section {
        var emailRow = Row(text: NSLocalizedString("Set Email", comment: "cell title"), cellClass: Value1Cell.self)
        emailRow.accessory = .disclosureIndicator
        emailRow.selection = {
//            let accountViewController = AccountViewController()
//            accountViewController.hidesBottomBarWhenPushed = true
//            self.showSettingsViewController(accountViewController)
        }
        
        var facebookRow = Row(text: NSLocalizedString("Facebook", comment: "cell title"), cellClass: Value1Cell.self)
//        facebookRow.accessory = .disclosureIndicator
        facebookRow.selection = {
            
        }
        
        return Section(header: .title("Account"), rows: [emailRow, facebookRow])
    }
    
    var signOutSection: Section {
        var signOutRow = Row(text: NSLocalizedString("Sign Out", comment: "cell title"), cellClass: Value1Cell.self)
        signOutRow.selection = {
            try! Auth.auth().signOut()
        }
        return Section(rows: [signOutRow])
    }
}
