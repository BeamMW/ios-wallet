//
// SplitCoinsStripeView.swift
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

final class SplitCoinsStripeView: UIView {

    static let palette: [UIColor] = [
        UIColor.main.brightTeal,
        UIColor.main.heliotrope,
        UIColor.main.green,
        UIColor.main.brightSkyBlue,
        UIColor.main.blueyGrey,
    ]

    private var amounts: [UInt64] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        layer.cornerRadius = 4
        backgroundColor = UIColor.white.withAlphaComponent(0.06)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setAmounts(_ amounts: [UInt64]) {
        self.amounts = amounts
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        subviews.forEach { $0.removeFromSuperview() }

        let total = amounts.reduce(UInt64(0), +)
        guard total > 0 else { return }

        var x: CGFloat = 0
        let h = bounds.height
        let w = bounds.width

        for (idx, value) in amounts.enumerated() {
            let segmentWidth = w * CGFloat(Double(value) / Double(total))
            let seg = UIView(frame: CGRect(x: x, y: 0, width: segmentWidth, height: h))
            seg.backgroundColor = SplitCoinsStripeView.palette[idx % SplitCoinsStripeView.palette.count]
            addSubview(seg)
            x += segmentWidth
        }
    }

    static func color(forIndex index: Int) -> UIColor {
        return palette[index % palette.count]
    }
}
