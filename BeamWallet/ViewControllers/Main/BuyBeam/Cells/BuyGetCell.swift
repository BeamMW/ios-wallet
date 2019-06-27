//
//  BuyGetCell.swift
//  BeamWallet
//
//  Created by Denis on 6/19/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class BuyGetCell: BaseCell {

    @IBOutlet weak private var valueLabel: UILabel!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var activityIndicator: UIActivityIndicatorView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.text = Localizable.shared.strings.you_get.uppercased()
        titleLabel.letterSpacing = 1.5
        
        selectionStyle = .none
    }
    
    public var isLoading:Bool = false {
        didSet{
            isLoading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
            valueLabel.alpha = (isLoading ? 0 : 1)
        }
    }
}

extension BuyGetCell: Configurable {
    
    func configure(with value:String) {
        if value.isEmpty {
            valueLabel.text = Localizable.shared.strings.beam_to_receive
            valueLabel.textColor = UIColor.main.steelGrey
        }
        else{
            valueLabel.text = value + Localizable.shared.strings.beam
            valueLabel.textColor = UIColor.main.brightSkyBlue
        }
    }
}
