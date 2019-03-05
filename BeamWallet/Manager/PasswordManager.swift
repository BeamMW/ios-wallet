//
//  PasswordManager.swift
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

import Foundation

class PasswordTestManager {
    
    enum State: String {
        case none = ""
        case veryWeak = "Very weak password"
        case weak = "Weak password"
        case medium = "Medium strength password"
        case strong = "Strong password"
        case veryStrong = "Very strong password"
    }
    
    fileprivate class PasswordTest {
        var exp:NSRegularExpression!
        var state:State!
        
        init(exp: NSRegularExpression, state: State) {
            self.exp = exp
            self.state = state
        }
    }
    
    static fileprivate let strengthTests = [PasswordTest(exp: try! NSRegularExpression(pattern: "(?=.{1,})"),
                                      state: State.veryWeak),
                         PasswordTest(exp: try! NSRegularExpression(pattern: "((?=.{6,})(?=.*[0-9]))|((?=.{6,})(?=.*[A-Z]))|((?=.{6,})(?=.*[a-z]))"),
                                      state: State.weak),
                         PasswordTest(exp: try! NSRegularExpression(pattern: "((?=.{6,})(?=.*[A-Z])(?=.*[a-z]))|((?=.{6,})(?=.*[0-9])(?=.*[a-z]))"),
                                      state: State.medium),
                         PasswordTest(exp: try! NSRegularExpression(pattern: "(?=.{8,})(?=.*[0-9])(?=.*[A-Z])(?=.*[a-z])"),
                                      state: State.medium),
                         PasswordTest(exp: try! NSRegularExpression(pattern: "(?=.{10,})(?=.*[0-9])(?=.*[A-Z])(?=.*[a-z])"),
                                      state: State.strong),
                         PasswordTest(exp: try! NSRegularExpression(pattern: "(?=.{10,})(?=.*[!@#$%^&*])(?=.*[0-9])(?=.*[A-Z])(?=.*[a-z])"),
                                      state: State.veryStrong)
                         ]
    
    static func testPassword(password:String) -> State {
        var state = State.none

        if password.isEmpty {
            return state
        }
        
        let range = NSRange(location: 0, length: password.utf16.count)

        for test in strengthTests {
            if(test.exp.firstMatch(in: password, options: [], range: range) != nil)
            {
                state = test.state
            }
        }
        
        return state
    }
    
}
