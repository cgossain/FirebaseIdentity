//
//  AuthProcedure.swift
//  AppController
//
//  Created by Christian Gossain on 2019-08-08.
//

import ProcedureKit
import FirebaseCore
import FirebaseAuth

final class AuthProcedure<P: IdentityProvider>: Procedure {
    let provider: P
    let authenticationType: AuthenticationType
    let completion: AuthDataResultCallback
    
    
    // MARK: - Lifecycle
    init(provider: P, authenticationType: AuthenticationType, completion: @escaping AuthDataResultCallback) {
        self.provider = provider
        self.authenticationType = authenticationType
        self.completion = completion
        super.init()
    }
    
    
    // MARK: - Procedure
    override func execute() {
        switch authenticationType {
        case .signUp:
            provider.signUp { [unowned self] (result, error) in
                self.completion(result, error)
                self.finish()
            }
            
        case .signIn:
            provider.signIn { (result, error) in
                self.completion(result, error)
                self.finish()
            }
            
        case .reauthenticate:
            provider.reauthenticate { (result, error) in
                self.completion(result, error)
                self.finish()
            }
        }
    }
}
