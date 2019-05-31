//
// BiometricAuthorization.swift
// BeamWallet
//
// Copyright 2018 Beam Development
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import LocalAuthentication

public typealias AuthorizationSuccess = (() -> ())

public typealias AuthorizationFailure = (() -> ())

public typealias AuthorizationRetry = (() -> ())

class BiometricAuthorization: NSObject {
    
    public static let shared = BiometricAuthorization()
    
    public func canAuthenticate() -> Bool {
        var isBiometricAuthenticationAvailable = false
        var error: NSError? = nil
        
        if LAContext().canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricAuthenticationAvailable = (error == nil)
        }
        
        if error?.code == -8
        {
            return true
        }
        
        return isBiometricAuthenticationAvailable
    }
    
    public func faceIDAvailable() -> Bool {
        
        if #available(iOS 11.0, *) {
            let context = LAContext()
            return (context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil) && context.biometryType == .faceID)
        }
        return false
    }
    
    public func touchIDAvailable() -> Bool {
        
        let context = LAContext()
        var error: NSError?
        
        let canEvaluate = context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if #available(iOS 11.0, *) {
            return canEvaluate && context.biometryType == .touchID
        }
        return canEvaluate
    }
    
    public func authenticateWithBioMetrics(success successBlock: @escaping AuthorizationSuccess, failure failureBlock: @escaping AuthorizationFailure, retry retryBlock: @escaping AuthorizationRetry, reasonText:String? = nil) {
        
        let mechanism = BiometricAuthorization.shared.faceIDAvailable() ? "Face ID" : "Touch ID"

         var reason = ""
        
        if let value = reasonText {
            reason = value
        }
        else{
            reason = faceIDAvailable() ? "Confirm your face to authenticate" : "Confirm your fingerprint to authenticate"
        }
        
        let context = LAContext()
        context.localizedFallbackTitle = ""
        context.touchIDAuthenticationAllowableReuseDuration = 0
        
        context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { (success, error) in
            DispatchQueue.main.async {
                if success {
                    successBlock()
                }
                else {
                    if error != nil && (error as NSError?)?.code == -8
                    {
                        let context : LAContext = LAContext();
                        
                        let reason:String = "\(mechanism) has been locked out due to few fail attemp. Enter iPhone passcode to enable TouchID.";
                        context.evaluatePolicy(LAPolicy.deviceOwnerAuthentication,
                                               localizedReason: reason,
                                               reply: { (success, error) in
                                                
                                                DispatchQueue.main.async {
                                                    if (success) {
                                                        retryBlock()
                                                    }
                                                    else{
                                                        failureBlock()
                                                    }
                                                    
                                                }
                        })
                    }
                    else{
                        failureBlock()
                    }
                }
            }
        }
    }
}
