//
// BiometricAuthorization.swift
// BeamWallet
//
// Copyright 2026 Beam Development
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

public typealias AuthorizationSuccess = (() -> Void)

public typealias AuthorizationFailure = (() -> Void)

public typealias AuthorizationRetry = (() -> Void)

@objc public enum BiometricFailureReason: Int {
    case canceled
    case notEnrolled
    case lockout
    case notAvailable
    case authenticationFailed
    case other
}

class BiometricAuthorization: NSObject {

    public static let shared = BiometricAuthorization()
    public var isAuthorizationProccess = false
    public private(set) var lastFailureReason: BiometricFailureReason?
    /// The LAContext that was just authenticated. Pass this to
    /// `KeychainManager.getPassword(context:)` inside the success callback
    /// to read the password without triggering a second biometric prompt.
    /// Becomes nil on the next authentication attempt.
    public private(set) var lastAuthenticatedContext: LAContext?
    private var mechanism = ""

    public func canAuthenticate() -> Bool {
        var error: NSError?
        let canEvaluate = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return canEvaluate && error == nil
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

    public func failureMessage(for reason: BiometricFailureReason) -> String {
        let strings = Localizable.shared.strings
        switch reason {
        case .lockout:
            return strings.auth_bio_locked.replacingOccurrences(of: "(Mechanism)", with: mechanism)
        case .notEnrolled:
            return strings.auth_bio_not_enrolled.replacingOccurrences(of: "(Mechanism)", with: mechanism)
        case .notAvailable:
            return strings.auth_bio_unavailable.replacingOccurrences(of: "(Mechanism)", with: mechanism)
        case .authenticationFailed, .other:
            return strings.auth_bio_failed.replacingOccurrences(of: "(Mechanism)", with: mechanism)
        case .canceled:
            return ""
        }
    }

    public func authenticateWithBioMetrics(success successBlock: @escaping AuthorizationSuccess, failure failureBlock: @escaping AuthorizationFailure, retry retryBlock: @escaping AuthorizationRetry, reasonText:String? = nil) {

        isAuthorizationProccess = true
        lastFailureReason = nil
        lastAuthenticatedContext = nil

        if mechanism.isEmpty {
            mechanism = BiometricAuthorization.shared.faceIDAvailable() ? Localizable.shared.strings.face_id : Localizable.shared.strings.touch_id
        }

        let reason = reasonText ?? (faceIDAvailable() ? Localizable.shared.strings.auth_face_confirm : Localizable.shared.strings.auth_touch_confirm)

        let context = LAContext()
        context.localizedFallbackTitle = ""
        context.touchIDAuthenticationAllowableReuseDuration = 0

        context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { (success, error) in
            DispatchQueue.main.async {
                if success {
                    self.lastFailureReason = nil
                    self.lastAuthenticatedContext = context
                    successBlock()
                } else {
                    self.lastFailureReason = Self.classify(error)
                    self.lastAuthenticatedContext = nil
                    failureBlock()
                }
                self.isAuthorizationProccess = false
            }
        }
    }

    private static func classify(_ error: Error?) -> BiometricFailureReason {
        guard let nsError = error as NSError? else { return .other }
        switch nsError.code {
        case LAError.userCancel.rawValue,
             LAError.systemCancel.rawValue,
             LAError.appCancel.rawValue:
            return .canceled
        case LAError.biometryNotEnrolled.rawValue:
            return .notEnrolled
        case LAError.biometryLockout.rawValue:
            return .lockout
        case LAError.biometryNotAvailable.rawValue,
             LAError.passcodeNotSet.rawValue:
            return .notAvailable
        case LAError.authenticationFailed.rawValue:
            return .authenticationFailed
        default:
            return .other
        }
    }
}
