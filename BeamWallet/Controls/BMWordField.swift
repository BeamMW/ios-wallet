//
//  BMWordField.swift
//  BeamWallet
//
// 3/1/19.
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

import UIKit

class BMWordField: BMField {
    
    enum FieldState {
        case correct
        case error
        case empty
    }
    
    private let errorColor = UIColor.main.red
    private let normalColor = AppDelegate.CurrentTarget == .Test ? UIColor.main.marineTwo : UIColor.main.darkSlateBlue

    var fState: FieldState! = .none {
        didSet {
            switch fState {
            case .empty?:
                self.textColor = UIColor.white
                self.line.backgroundColor = normalColor
                break
            case .error?:
                self.textColor = errorColor
                self.line.backgroundColor = errorColor
                break
            case .correct?:
                self.textColor = UIColor.white
                self.line.backgroundColor = normalColor
                break
            case .none:
                break
            }
        }
    }
}
