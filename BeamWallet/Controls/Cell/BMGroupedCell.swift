//
//  BMGroupedCell.swift
//  BeamWallet
//
//  Created by Denis on 7/19/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class BMGroupedCell: BaseCell {

    enum BMGroupedCellPosition: Int {
        case top = 1
        case center = 2
        case bottom = 3
        case one = 4
    }
    
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var topView: UIView!
    @IBOutlet weak private var botView: UIView!
    @IBOutlet weak private var bottomOffset: NSLayoutConstraint!
    
    public var titleColor:UIColor = UIColor.white {
        didSet{
            titleLabel.textColor = titleColor
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.textColor = titleColor
        
        topView.backgroundColor = UIColor.white.withAlphaComponent(0.13)
        botView.backgroundColor = UIColor.white.withAlphaComponent(0.13)

        selectionStyle = .default
        
        contentView.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear
        mainView.backgroundColor = UIColor.main.cellBackgroundColor
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.main.selectedColor
        self.selectedBackgroundView = selectedView
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        mainView.backgroundColor = highlighted ? UIColor.main.selectedColor : UIColor.main.cellBackgroundColor
    }
}

extension BMGroupedCell: Configurable {
    
    func configure(with options: (text:String, position:BMGroupedCellPosition)) {
        topView.isHidden = false
        botView.isHidden = false
        bottomOffset.constant = 0
        
        titleLabel.text = options.text
        
        if options.position == .top {
            bottomOffset.constant = 15
        }
        else if options.position == .bottom {
            topView.isHidden = true
        }
    }
}
