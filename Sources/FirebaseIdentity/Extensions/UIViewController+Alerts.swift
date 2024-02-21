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
    
    /// Presents a simple alert with details of an `AuthenticationError`..
    public func showAuthenticationErrorAlert(for error: AuthenticationError) {
        let alert = UIAlertController(title: LocalizedString("Error", comment: "alert title"), message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: "alert action title"), style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    /// Presents a simple alert with details of an `ProfileChangeError`.
    public func showProfileChangeErrorAlert(for error: ProfileChangeError) {
        switch error {
        case .cancelledByUser:
            break
        default:
            let alert = UIAlertController(title: LocalizedString("Error", comment: "alert title"), message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: "alert action title"), style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
}
