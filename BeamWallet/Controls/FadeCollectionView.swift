//
// FadeCollectionView.swift
// BeamWallet
//
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

import Foundation

class FadingCollectionView: UICollectionView {
    
    private var gradientWidth: CGFloat = 100
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = .clear
        let maskLayer = CAGradientLayer()
        maskLayer.anchorPoint = CGPoint.zero
        maskLayer.startPoint = CGPoint(x: 0, y: 0)
        maskLayer.endPoint = CGPoint(x: 1, y: 0)
        let outerColor = UIColor(white: 1.0, alpha: 0.0)
        let innerColor = UIColor(white: 1.0, alpha: 1.0)
        maskLayer.colors = [outerColor.cgColor, innerColor.cgColor, innerColor.cgColor, outerColor.cgColor]
        let firstValue = Double(gradientWidth/frame.size.width)
        let secondValue = Double((frame.size.width - gradientWidth)/frame.size.width)
        maskLayer.locations = [0, NSNumber(value: firstValue), NSNumber(value: secondValue), 1]
        maskLayer.frame = bounds
        layer.masksToBounds = true
        layer.mask = maskLayer
    }
    
}
