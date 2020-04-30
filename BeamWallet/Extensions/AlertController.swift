//
// AlertController.swift
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

private extension UIView
{
    func searchVisualEffectsSubview() -> UIVisualEffectView?
    {
        if let visualEffectView = self as? UIVisualEffectView
        {
            return visualEffectView
        }
        else
        {
            for subview in subviews
            {
                if let found = subview.searchVisualEffectsSubview()
                {
                    return found
                }
            }
        }
        
        return nil
    }
}

extension UIAlertController {
    // Set background color of UIAlertController
    func setBackgroundColor(color: UIColor) {
        if let visualEffectView = self.view.searchVisualEffectsSubview()
        {
            visualEffectView.effect = UIBlurEffect(style: .dark)
        }
        
//        if let bgView = self.view.subviews.first, let groupView = bgView.subviews.first, let contentView = groupView.subviews.first {
//            contentView.layer.cornerRadius = 0
//            contentView.layer.borderWidth = 0
//            contentView.clipsToBounds = true
//            contentView.backgroundColor = preferredStyle == .actionSheet  ? UIColor.clear : color
//        }
    }
}

