//
//  DeleteDatabaseRefsOperation.swift
//  MooveFitCoreKit
//
//  Created by Christian Gossain on 2020-01-13.
//

import Foundation
import ProcedureKit
import FirebaseDatabase

/// An operation that deletes the data at the given database refs.
final class DeleteDatabaseRefsOperation: Procedure {
    /// The database refs to be deleted.
    let refs: [DatabaseReference]
    
    /// A block called when the operation completes but just before the operation moves to the `finished` state.
    var deleteDatabaseRefsCompletionBlock: ((Error?) -> Void)?
    
    
    // MARK: - Private Properties
    private var queue: ProcedureQueue = {
        let queue = ProcedureQueue()
        queue.name = "com.firebaseIdentity.authManager.deleteDatabaseRefsProcedureQueue"
        return queue
    }()
    
    
    // MARK: - Lifecycle
    init(refs: [DatabaseReference]) {
        self.refs = refs
        super.init()
    }
    
    override func execute() {
        var opError: Error?
        
        defer {
            // call the completion block
            deleteDatabaseRefsCompletionBlock?(opError)
            
            // finish after all operations in the
            // operation queue have finished
            finish()
        }
        
        // delete each ref
        for ref in refs {
            let op = DeleteDatabaseRefOperation(ref: ref)
            op.deleteDatabaseRefCompletionBlock = { (error) in
                if let error = error {
                    opError = error
                }
            }
            queue.addOperation(op)
        }
        
        queue.waitUntilAllOperationsAreFinished()
    }
}

/// An operation that deletes the data at a given ref using a transaction block.
private final class DeleteDatabaseRefOperation: Procedure {
    /// The database refs to be deleted.
    let ref: DatabaseReference
    
    /// A block called when the operation completes but just before the operation moves to the `finished` state.
    var deleteDatabaseRefCompletionBlock: ((Error?) -> Void)?
    
    
    // MARK: - Lifecycle
    init(ref: DatabaseReference) {
        self.ref = ref
        super.init()
    }
    
    override func execute() {
        DispatchQueue.main.async {
            self.ref.runTransactionBlock({ (data) -> TransactionResult in
                data.value = nil
                return TransactionResult.success(withValue: data)
            }) { [unowned self] (error, success, snapshot) in
                self.deleteDatabaseRefCompletionBlock?(error)
                self.finish()
            }
        }
    }
}
