//
//  UIViewController+Alerts.swift
//  FirebaseIdentity
//
//  Created by Christian Gossain on 2019-12-17.
//

import Foundation

extension UIViewController {
    /// Presents a simple alert with details of an `AuthenticationError`..
    public func showAuthenticationErrorAlert(for error: AuthenticationError) {
        let alert = UIAlertController(title: LocalizedString("Error", comment: "alert title"), message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: "alert action title"), style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    /// Presents a simple alert with details of an `ProfileChangeError`.
    public func showProfileChangeErrorAlert(for error: ProfileChangeError) {
        switch error {
        case .cancelledByUser(_):
            break // ignore
        default:
            let alert = UIAlertController(title: LocalizedString("Error", comment: "alert title"), message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: "alert action title"), style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    /// Presents a simple alert with details of an `DeleteAccountOperationError`.
    public func showDeleteAccountOperationErrorAlert(for error: DeleteAccountOperationError) {
        switch error {
        case .cancelledByUser:
            break // ignore
        default:
            let alert = UIAlertController(title: LocalizedString("Error", comment: "alert title"), message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: "alert action title"), style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
}
