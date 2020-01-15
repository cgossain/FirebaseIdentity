//
//  DeleteUserAccountOperation.swift
//  MooveFitCoreKit
//
//  Created by Christian Gossain on 2020-01-13.
//

import Foundation
import ProcedureKit
import FirebaseAuth

/// An operation that delete the currently authenticated Firebase user.
final class DeleteUserAccountOperation: Procedure {
    /// A block called when the operation completes but just before the operation moves to the `finished` state.
    var deleteFirebaseUserCompletionBlock: ProfileChangeHandler?
    
    
    // MARK: - Lifecycle
    override func execute() {
        DispatchQueue.main.async {
            // using this internal method (as opossed to the deleteAccount on the firebase user directly)
            // has the benefit of tying into the AuthManager's error handling mechanism
            AuthManager.shared.deleteAccount { (result) in
                self.deleteFirebaseUserCompletionBlock?(result)
                self.finish()
            }
        }
    }
}
