//
//  SeedIntroCell.swift
//  BeamWallet
//
//  Created by Denis on 10/18/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class SeedIntroCell: UICollectionViewCell {

    static let reuseIdentifier = "SeedIntroCell"
    static let nib = "SeedIntroCell"
    
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var iconView: UIImageView!

    lazy var w: NSLayoutConstraint = {
        let width = contentView.widthAnchor.constraint(equalToConstant: bounds.size.width)
        width.isActive = true
        return width
    }()
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        w.constant = bounds.size.width
        return contentView.systemLayoutSizeFitting(CGSize(width: targetSize.width, height: 1))
    }
}

extension SeedIntroCell: Configurable {
    
    func configure(with options: (text: String, image:UIImage?)) {
        iconView.image = options.image
        textLabel.text = options.text
    }
}
