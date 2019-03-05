//
//  WordCell.swift
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

class WordCell: UICollectionViewCell {

    static let reuseIdentifier = "WordCell"
    static let nib = "WordCell"

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
