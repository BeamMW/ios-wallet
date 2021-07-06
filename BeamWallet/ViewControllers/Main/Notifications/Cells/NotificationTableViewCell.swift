//
//  NotificationTableViewCell.swift
//  BeamWallet
//
//  Created by Denis on 29.04.2020.
//  Copyright © 2020 Denis. All rights reserved.
//

import UIKit

class NotificationTableViewCell: RippleCell {

    @IBOutlet weak private var topOffset: NSLayoutConstraint!
    @IBOutlet weak private var bottomOffset: NSLayoutConstraint!
 

    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var detailLabel: UILabel!
    @IBOutlet weak private var dateLabel: UILabel!
    @IBOutlet weak private var iconView: UIImageView!

    private var mainViewColor:UIColor?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        dateLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
    }
}

extension NotificationTableViewCell: Configurable {
    
    func configure(with options: (row: Int, item:NotificationItem)) {
        if options.item.isRead {
            topOffset.constant = 0
            bottomOffset.constant = 0
            mainView.backgroundColor = (options.row % 2 == 0) ? UIColor.main.cellBackgroundColor : UIColor.main.marine
        }
        else {
            topOffset.constant = 10
            bottomOffset.constant = 10
            mainView.backgroundColor = UIColor.main.marineThree
        }
        
        mainViewColor = mainView.backgroundColor

        nameLabel.text = options.item.name
        detailLabel.attributedText = options.item.detail
        dateLabel.text = options.item.date
        iconView.image = options.item.icon
        detailLabel.isHidden = options.item.detail == nil
    }
}
