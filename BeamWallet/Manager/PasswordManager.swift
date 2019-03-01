//
//  PasswordManager.swift
//  BeamWallet
//
//  Created by Denis on 3/1/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import Foundation

class PasswordTestManager {
    
    enum State: String {
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
       
        let range = NSRange(location: 0, length: password.utf16.count)

        var state = State.veryWeak
        
        for test in strengthTests {
            if(test.exp.firstMatch(in: password, options: [], range: range) != nil)
            {
                state = test.state
            }
        }
        
        return state
    }
    
}
