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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = CGRect(x:7, y: 7, width: 12, height: 10)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.addSubview(imageView)
    }
    
    public func setAsset(_ asset:BMAsset) {
        if asset.isBeam() {
            imageView.image = UIImage(named: "ic_asset_beam")
            imageView.frame = CGRect(x:5, y: 5, width: 15, height: 13)
        }
        else {
            imageView.image = UIImage(named: "ic_asset")
            imageView.frame = CGRect(x:7, y: 7, width: 12, height: 10)
        }
        
        self.gradientLayer.type = .radial
        self.gradientLayer.colors = [
            UIColor(hexString: asset.color).withAlphaComponent(0.7).cgColor,
            UIColor.black]
        self.gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        self.gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        self.cornerRadius = 13
        self.borderWidth = 2
        self.borderColor = UIColor(hexString: asset.color)
    }

}
