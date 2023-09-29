//
//  DeleteDatabaseRefsOperation.swift
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
import FirebaseDatabase

/// An operation that deletes the data at the given database refs.
final class DeleteDatabaseRefsOperation: Procedure {
    
    /// The database refs to be deleted.
    let refs: [DatabaseReference]?
    
    /// A block called when the operation completes but just before the operation moves to the `finished` state.
    var deleteDatabaseRefsCompletionBlock: ((Error?) -> Void)?
    
    // MARK: - Private
    
    private var queue: ProcedureQueue = {
        let queue = ProcedureQueue()
        queue.name = "com.firebaseIdentity.authManager.deleteDatabaseRefsProcedureQueue"
        return queue
    }()
    
    // MARK: - Init
    
    init(refs: [DatabaseReference]?) {
        self.refs = refs
        super.init()
    }
    
    // MARK: - Procedure
    
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
        guard let refs = self.refs else {
            return // no refs provided; finish immediately; defer will finish
        }
        
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
    
    // MARK: - Init
    
    init(ref: DatabaseReference) {
        self.ref = ref
        super.init()
    }
    
    // MARK: - Procedure
    
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
