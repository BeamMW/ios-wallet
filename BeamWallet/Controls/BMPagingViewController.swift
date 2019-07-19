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


class BMPagingView: PagingView {
    
    var menuTopConstraint: NSLayoutConstraint?
    
    override func setupConstraints() {
        pageView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        menuTopConstraint = collectionView.topAnchor.constraint(equalTo: topAnchor)
        menuTopConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: options.menuHeight),
            
            pageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            pageView.topAnchor.constraint(equalTo: topAnchor)
            ])
    }
}

class BMPagingViewController: PagingViewController<PagingIndexItem> {
    
    override func loadView() {
        let custom =  PagingView(
            options: options,
            collectionView: collectionView,
            pageView: pageViewController.view
        )
        custom.options.indicatorColor = UIColor.main.brightTeal
        custom.options.font = BoldFont(size: 16)
        custom.options.selectedFont = BoldFont(size: 16)
        custom.options.textColor = UIColor.main.blueyGrey
        custom.options.selectedTextColor = UIColor.main.blueyGrey
        custom.options.menuBackgroundColor = UIColor.main.marine
        custom.options.backgroundColor = UIColor.clear
        custom.options.borderColor = UIColor.clear
        custom.options.menuItemSpacing = 0
        custom.backgroundColor = UIColor.clear
        
        contentInteraction = .none
        
        view = custom
        view.clipsToBounds = true
    }
}
