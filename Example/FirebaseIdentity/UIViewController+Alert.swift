//
//  UIViewController+Alert.swift
//  FirebaseIdentity_Example
//
//  Created by Christian Gossain on 2019-08-02.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import FirebaseIdentity

extension UIViewController {
    func showAlert(withTitle title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func showAlert(for error: NSError) {
        let msg = error.localizedDescription + "\n\n" + "Error Code: \(error.code)" + "\n\n" + error.userInfo.description
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func showAlert(for error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
