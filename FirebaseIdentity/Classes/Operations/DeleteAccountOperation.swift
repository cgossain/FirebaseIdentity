//
//  DeleteAccountOperation.swift
//  MooveFitCoreKit
//
//  Created by Christian Gossain on 2020-01-13.
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
        
        // 1. request reauthentication
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
