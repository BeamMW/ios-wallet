//
// BMPagingViewController.swift
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
import Parchment

class PagingLargeTitleCell : PagingTitleCell {
    
    override func configureTitleLabel() {
        super.configureTitleLabel()
        
        titleLabel.adjustFontSize = true
        titleLabel.letterSpacing = 1.5
    }
}

class BMPagingViewController: PagingViewController<PagingIndexItem> {
    
    override func loadView() {
        
        var fontSize:CGFloat = 14
        
        if Device.screenType == .iPhone_XSMax || Device.screenType == .iPhones_Plus {
            fontSize = fontSize + 1.0
        }
        else if Device.screenType == .iPhones_5{
            fontSize = fontSize - 1.5
        }
        
        let custom =  PagingView(
            options: options,
            collectionView: collectionView,
            pageView: pageViewController.view
        )
        custom.options.indicatorColor = UIColor.main.brightTeal
        custom.options.font = BoldFont(size: fontSize)
        custom.options.selectedFont = BoldFont(size: fontSize)
        custom.options.textColor = UIColor.main.blueyGrey
        custom.options.selectedTextColor = UIColor.main.blueyGrey
        custom.options.menuBackgroundColor = UIColor.main.marine
        custom.options.backgroundColor = UIColor.clear
        custom.options.borderColor = UIColor.clear
        custom.options.menuItemSpacing = 0
        custom.backgroundColor = UIColor.clear
        contentInteraction = .none
        menuItemSource = .class(type: PagingLargeTitleCell.self)

        view = custom
        view.clipsToBounds = true
    }
}
