//
//  WordCell.swift
//  BeamWallet
//
//  Created by Denis on 3/1/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class WordCell: UICollectionViewCell {

    static let reuseIdentifier = "WordCell"

    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

extension WordCell: Configurable {
    
    func configure(with options: (word: String, number:String)) {
        wordLabel.text = options.word
        numberLabel.text = options.number
    }
}
