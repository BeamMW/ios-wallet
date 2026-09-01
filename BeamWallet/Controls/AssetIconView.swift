//
// AssetIconView.swift
// BeamWallet
//
// Copyright 2026 Beam Development
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

class AssetIconView: BMGradientView {
    
    private let imageView = UIImageView(image: UIImage(named: "ic_asset"))
    private let verify = UIImageView(image: UIImage(named: "ic_verify-1"))

    public var isBig = false

    private var glyphReferenceSize: CGSize?
    private var glyphFillsBounds = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        verify.frame = CGRect(x: self.width-10, y: -3, width: 13, height: 13)
        layoutImageView()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }

    private func commonInit() {
        self.cornerRadius = self.frame.width/2
        if imageView.superview !== self {
            self.addSubview(imageView)
        }
    }

    public func setAsset(_ asset:BMAsset) {
        verify.removeFromSuperview()

        if isBig {
            if asset.isBeamX() {
                addSubview(verify)
                imageView.image = UIImage(named: "assetbeamx")
                glyphReferenceSize = nil
                glyphFillsBounds = true
            }
            else if asset.isBeam() {
                imageView.image = UIImage(named: "ic_asset_beam_big")
                glyphReferenceSize = CGSize(width: 24, height: 20)
                glyphFillsBounds = false
            }
            else {
                imageView.image = UIImage(named: "ic_asset_big")
                glyphReferenceSize = CGSize(width: 23, height: 19)
                glyphFillsBounds = false
            }
        }
        else {
            if asset.isBeamX() {
                addSubview(verify)
                imageView.image = UIImage(named: "assetbeamx")
                glyphReferenceSize = nil
                glyphFillsBounds = true
            }
            else if asset.isBeam() {
                imageView.image = UIImage(named: "ic_asset_beam")
                glyphReferenceSize = CGSize(width: 15, height: 13)
                glyphFillsBounds = false
            }
            else {
                imageView.image = UIImage(named: "ic_asset")
                glyphReferenceSize = CGSize(width: 12, height: 10)
                glyphFillsBounds = false
            }

            self.gradientLayer.type = .radial
            self.gradientLayer.colors = [
                UIColor(hexString: asset.color).withAlphaComponent(0.7).cgColor,
                UIColor.black]
            self.gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
            self.gradientLayer.endPoint = CGPoint(x: 1, y: 1)

            self.borderWidth = 2
            self.borderColor = UIColor(hexString: asset.color)

            if asset.isBeamX() {
                self.borderWidth = 0
                self.gradientLayer.colors = nil
            }
        }

        setNeedsLayout()
    }

    private func layoutImageView() {
        if glyphFillsBounds {
            imageView.frame = bounds
            return
        }
        guard let refSize = glyphReferenceSize, bounds.width > 0 else { return }
        let referenceFrame: CGFloat = isBig ? 48 : 28
        let scale = bounds.width / referenceFrame
        let size = CGSize(width: refSize.width * scale, height: refSize.height * scale)
        imageView.frame = CGRect(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }
}

