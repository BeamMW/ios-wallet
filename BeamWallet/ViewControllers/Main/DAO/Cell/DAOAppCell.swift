//
//  DAOAppCell.swift
//  BeamWallet
//
//  Created by Denis on 08.09.2021.
//  Copyright © 2026 Denis. All rights reserved.
//

import UIKit
import SDWebImage

class DAOAppCell: RippleCell {

    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var detailLabel: UILabel!
    @IBOutlet weak private var iconView: UIImageView!
    @IBOutlet weak private var iconMainView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.sd_cancelCurrentImageLoad()
        iconView.image = nil
    }
}

extension DAOAppCell: Configurable {

    func configure(with options: (row: Int, app:BMApp)) {

        iconMainView.backgroundColor = UIColor.main.marineThree
        mainView.backgroundColor = UIColor.white.withAlphaComponent(0.1)

        nameLabel.text = options.app.name
        iconView.sd_cancelCurrentImageLoad()
        if options.app.name.lowercased() == "beamx dao" {
            iconView.image = UIImage(named: "dao_app_icon")
        }
        else {
            // Force the SVG coder onto its bitmap path. The default vector path
            // returns a UIImage backed by a live CGSVGDocumentRef, which CoreSVG
            // re-renders on every draw — that crashes when scrolling on iOS 17+.
            let pixelSize = CGSize(width: 96, height: 96) // 32pt @3x
            let context: [SDWebImageContextOption: Any] = [
                .imageThumbnailPixelSize: NSValue(cgSize: pixelSize),
                .imagePreserveAspectRatio: true,
            ]
            iconView.sd_setImage(
                with: URL(string: options.app.icon),
                placeholderImage: nil,
                context: context
            )
        }
        
        if options.app.isSupported {
            detailLabel.text = options.app.desc
            detailLabel.alpha = 0.7
            detailLabel.textColor = UIColor.white
            detailLabel.font = RegularFont(size: 14)
            self.isUserInteractionEnabled = true
        }
        else {
            detailLabel.text = String.init(format:Localizable.shared.strings.app_not_supported, options.app.api_version ?? "")
            detailLabel.textColor = UIColor.main.red
            detailLabel.alpha = 1
            detailLabel.font = ItalicFont(size: 14)
            self.isUserInteractionEnabled = false
        }
    }
}

