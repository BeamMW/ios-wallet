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

class BiometricAuthorization: NSObject {
    
    public static let shared = BiometricAuthorization()
    
    public func canAuthenticate() -> Bool {
        
        var isBiometricAuthenticationAvailable = false
        var error: NSError? = nil
        
        if LAContext().canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricAuthenticationAvailable = (error == nil)
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
    
    public func authenticateWithBioMetrics(success successBlock: @escaping AuthorizationSuccess, failure failureBlock: @escaping AuthorizationFailure) {
        
        let reason = faceIDAvailable() ? "Confirm your face to authenticate" : "Confirm your fingerprint to authenticate"
        
        let context = LAContext()

        context.localizedFallbackTitle = ""
        context.touchIDAuthenticationAllowableReuseDuration = 60
        
        context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { (success, err) in
            DispatchQueue.main.async {
                if success {
                    successBlock()
                }
                else {
                    failureBlock()
                }
            }
        }
    }
}
