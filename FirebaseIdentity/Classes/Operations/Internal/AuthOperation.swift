//
//  AuthOperation.swift
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

import ProcedureKit
import FirebaseAuth

final class AuthOperation<P: IdentityProvider>: Procedure {
    let provider: P
    let authenticationType: AuthenticationType
    let completion: ((AuthDataResult?, Error?) -> Void)
    
    // MARK: - Init
    
    init(provider: P, authenticationType: AuthenticationType, completion: @escaping ((AuthDataResult?, Error?) -> Void)) {
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
            
        case .linkProvider:
            provider.link { (result, error) in
                self.completion(result, error)
                self.finish()
            }
        }
    }
}
