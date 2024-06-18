//
//  UIViewController+Alerts.swift
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

import UIKit

extension UIViewController {
    
    /// Presents a simple alert with details of an `AuthenticationError`.
    public func showAlertForAuthenticationError(_ authenticationError: AuthenticationError) {
        let title: String
        let msg: String
        switch authenticationError {
        case .requiresAccountLinking(let existingEmail, let existingProviders, let context):
            title = LocalizedString("Account Exists", comment: "alert title")
            let msgFmt = LocalizedString("It looks like we already have a user signed up as %@ via %@.", comment: "alert message")
            msg = String(format: msgFmt, existingEmail, String(describing: existingProviders[0]))
        default:
            title = LocalizedString("Error", comment: "alert title")
            msg = authenticationError.localizedDescription
        }
        
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: "alert action title"), style: .default))
        present(alert, animated: true)
    }
    
    /// Presents a simple alert with details of an `ProfileChangeError`.
    public func showAlertForProfileChangeError(_ profileChangeError: ProfileChangeError) {
        switch profileChangeError {
        case .cancelledByUser:
            break
        default:
            let alert = UIAlertController(title: LocalizedString("Error", comment: "alert title"), message: profileChangeError.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: "alert action title"), style: .default))
            present(alert, animated: true, completion: nil)
        }
    }
}
