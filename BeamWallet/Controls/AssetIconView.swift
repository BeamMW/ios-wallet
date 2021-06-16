//
//  AssetIconView.swift
//  BeamWallet
//
//  Created by Denis on 09.06.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

import UIKit

class AssetIconView: BMGradientView {

    private let imageView = UIImageView(image: UIImage(named: "ic_asset"))
    public var isBig = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.cornerRadius = self.frame.width/2

        self.addSubview(imageView)
    }
    
    public func setAsset(_ asset:BMAsset) {
        if isBig {
            if asset.isBeam() {
                imageView.image = UIImage(named: "ic_asset_beam_big")
                imageView.frame = CGRect(x:12, y: 11, width: 24, height: 20)
            }
            else {
                imageView.image = UIImage(named: "ic_asset_big")
                imageView.frame = CGRect(x:12, y: 11, width: 23, height: 19)
            }
        }
        else {
            if asset.isBeam() {
                imageView.image = UIImage(named: "ic_asset_beam")
                imageView.frame = CGRect(x:6, y: 5, width: 15, height: 13)
            }
            else {
                imageView.image = UIImage(named: "ic_asset")
                imageView.frame = CGRect(x:7, y: 7, width: 12, height: 10)
            }
        }
        
        self.gradientLayer.type = .radial
        self.gradientLayer.colors = [
            UIColor(hexString: asset.color).withAlphaComponent(0.7).cgColor,
            UIColor.black]
        self.gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        self.gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        self.borderWidth = 2
        self.borderColor = UIColor(hexString: asset.color)
    }

}
