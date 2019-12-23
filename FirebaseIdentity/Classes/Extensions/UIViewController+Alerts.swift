//
//  UIViewController+Alerts.swift
//  FirebaseIdentity
//
//  Created by Christian Gossain on 2019-12-17.
//

import Foundation

extension UIViewController {
    /// Presents a simple alert with details of an `AuthenticationError`.
    public func showAuthenticationErrorAlert(for error: AuthenticationError) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    /// Presents a simple alert with details of an `ProfileChangeError`.
    public func showProfileChangeErrorAlert(for error: ProfileChangeError) {
        switch error {
        case .cancelledByUser(_):
            break // ignore
        default:
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
}
