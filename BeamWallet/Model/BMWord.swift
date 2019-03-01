//
//  BMWord.swift
//  BeamWallet
//
//  Created by Denis on 3/1/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import Foundation

class BMWord {
    var value:String!
    var index:Int!
    var correct:Bool!
    
    init(word: String, index: Int, correct: Bool) {
        self.value = word
        self.index = index
        self.correct = correct
    }
}
