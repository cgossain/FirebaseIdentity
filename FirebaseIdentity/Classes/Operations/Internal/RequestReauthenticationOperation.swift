//
//  RequestReauthenticationOperation.swift
//  MooveFitCoreKit
//
//  Created by Christian Gossain on 2020-01-14.
//

import Foundation
import ProcedureKit

/// An operation that requests reauthentication via the `FirebaseIdentity.AuthManager` shared instance.
final class RequestReauthenticationOperation: Procedure {
    /// A block called when the operation completes but just before the operation moves to the `finished` state.
    var requestReauthenticationCompletionBlock: ((ProfileChangeError?) -> Void)?
    
    
    // MARK: - Lifecycle
    override func execute() {
        DispatchQueue.main.async {
            AuthManager.shared.requestReauthentication { (status) in
                switch status {
                case .success, .unnecessary:
                    self.requestReauthenticationCompletionBlock?(nil)
                case .failure(let error):
                    self.requestReauthenticationCompletionBlock?(error)
                }
                
                self.finish()
            }
        }
    }
}
