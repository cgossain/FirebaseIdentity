//
//  DeleteAccountOperation.swift
//
//  Copyright (c) 2019-2021 Christian Gossain
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

import Foundation
import ProcedureKit
import FirebaseAuth
import FirebaseDatabase

public enum DeleteAccountOperationError: Error {
    /// A user action caused the operation to be cancelled.
    ///
    /// Currently the only action that would trigger this error is if reauthentication is
    /// cancelled using the `cancelReauthentication(for:)` method on the AuthManager
    case cancelledByUser
    
    /// A generic error occured.
    case other(String)
}

/// The block that is invoked when the `DeleteAccountOperation` completes.
public typealias DeleteAccountHandler = (Result<DeletedUserMetadata, DeleteAccountOperationError>) -> Void

/// A lightweight object containing metadata about a deleted user.
public struct DeletedUserMetadata {
    public let uid: String
    public let displayName: String
    public let email: String
    
    public init(uid: String, displayName: String?, email: String?) {
        self.uid = uid
        self.displayName = displayName ?? "n/a"
        self.email = email ?? "n/a"
    }
}

/// An operation that follows a full account wipe procedure. This operation follows the below steps:
///
/// 1. Triggers reauthentication
/// 2. Deletes the data at the given database references
/// 3. Deletes the user account from Firebase
final public class DeleteAccountOperation: Procedure {
    /// The user data that should be deleted as part of the account deletion operation
    public let refs: [DatabaseReference]
    
    /// A block called when the operation completes but just before the operation moves to the `finished` state.
    public var deleteAccountCompletionBlock: DeleteAccountHandler?
    
    
    // MARK: - Private Properties
    private var queue: ProcedureQueue = {
        let queue = ProcedureQueue()
        queue.name = "com.firebaseIdentity.authManager.deleteAccountProcedureQueue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    
    // MARK: - Lifecycle
    public init(refs: [DatabaseReference]) {
        self.refs = refs
        super.init()
    }
    
    override public func execute() {
        var deletedUserMetadata: DeletedUserMetadata?
        var opError: DeleteAccountOperationError?
        
        defer {
            // call the completion block
            if let opError = opError {
                deleteAccountCompletionBlock?(.failure(.other(opError.localizedDescription)))
            }
            else {
                deleteAccountCompletionBlock?(.success(deletedUserMetadata!))
            }
            
            // finish after all operations in the
            // operation queue have finished
            finish()
        }
        
        // 2. delete account data
        let deleteAccountDataOp = DeleteDatabaseRefsOperation(refs: self.refs)
        deleteAccountDataOp.deleteDatabaseRefsCompletionBlock = { [unowned self] (deleteDataError) in
            if let deleteDataError = deleteDataError {
                opError = .other(deleteDataError.localizedDescription)
            }
            else {
                // 3a. copy metadata before deleting the user account
                let authenticatedUser = AuthManager.shared.authenticatedUser!
                let metadata = DeletedUserMetadata(uid: authenticatedUser.uid, displayName: authenticatedUser.displayName, email: authenticatedUser.email)
                deletedUserMetadata = metadata

                // 3b. delete user account
                let deleteUserOp = DeleteUserAccountOperation()
                deleteUserOp.deleteFirebaseUserCompletionBlock = { (result) in
                    switch result {
                    case .success(_):
                        break
                    case .failure(let error):
                        opError = .other(error.localizedDescription)
                    }
                }

                // add the operation
                self.queue.addOperation(deleteUserOp)
            }
        }
        
        // 1. opportunistically reauthenticate the user
        // if we don't force the user to reauthenticate prior to starting the account deletion process
        // we could potentially end up deleting all the user's data and then run into a "requiresRecentLogin"
        // error out when deleting the firebase account; to avoid this, and to make this process as smooth as
        // possible we can require reauthentication before starting this process
        let requestReauthenticationOp = RequestReauthenticationOperation()
        requestReauthenticationOp.requestReauthenticationCompletionBlock = { (profileChangeError) in
            if let profileChangeError = profileChangeError {
                switch profileChangeError {
                case .cancelledByUser(_):
                    opError = DeleteAccountOperationError.cancelledByUser
                default:
                    opError = DeleteAccountOperationError.other(profileChangeError.localizedDescription)
                }
            }
            else {
                // add the operation
                self.queue.addOperation(deleteAccountDataOp)
            }
        }

        // add the operation
        self.queue.addOperation(requestReauthenticationOp)

        // block the thread
        queue.waitUntilAllOperationsAreFinished()
    }
}
