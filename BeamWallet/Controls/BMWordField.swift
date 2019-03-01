//
//  BMWordField.swift
//  BeamWallet
//
//  Created by Denis on 3/1/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class BMWordField: BMField {
    
    enum FieldState {
        case correct
        case error
        case empty
    }
    
    private let errorColor = UIColor.main.red
    private let normalColor = UIColor.main.darkSlateBlue

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
