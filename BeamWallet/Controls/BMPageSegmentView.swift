//
// BMPageSegmentView.swift
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

import UIKit

class BMPageSegmentViewCell: UICollectionViewCell {
    
    private var label:UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        label = UILabel(frame: CGRect.zero)
        label.font = SemiboldFont(size: 20)
        label.textColor = UIColor.white
        label.textAlignment = .center
        addSubview(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.frame = self.bounds
    }
    
    public var text:String? {
        didSet{
            label.text = text?.uppercased()
        }
    }
    
    public var currentIndex:Bool = false {
        didSet{
            label.font = currentIndex ? ProMediumFont(size: 24) : ProRegularFont(size: 14)
        }
    }
}

class BMPageSegmentView: UIView {

    private var tabsCollectionView: FadingCollectionView!
    private var pages = ["Send","Receive","Swap"]
    private var tabMenuHeight: CGFloat = 50
    private var cellWidth: CGFloat = 0.0

    public var selectedPageIndex: Int = 0 {
        didSet {
            scrollContent(to: selectedPageIndex)
            tabsCollectionView.reloadData()
        }
    }
    
    init() {
        super.init(frame: CGRect(x: 50, y: 55, width: UIScreen.main.bounds.size.width-100, height: tabMenuHeight))
        
        for title in pages {
            let w = getTitleWidth(title: title, font: ProMediumFont(size: 24))
            if cellWidth < w {
                cellWidth = w
            }
        }
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        tabsCollectionView = FadingCollectionView(frame: self.bounds, collectionViewLayout: layout)
        tabsCollectionView.delegate = self
        tabsCollectionView.dataSource = self
        tabsCollectionView.showsHorizontalScrollIndicator = false
        tabsCollectionView.showsVerticalScrollIndicator = false
        tabsCollectionView.register(BMPageSegmentViewCell.self, forCellWithReuseIdentifier: BMPageSegmentViewCell.reuseIdentifier)
        addSubview(tabsCollectionView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
}

extension BMPageSegmentView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        return pages.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       
        let cell = collectionView.dequeueReusableCell(withType: BMPageSegmentViewCell.self, for: indexPath)
        
        cell.text = pages[indexPath.row]
        cell.currentIndex = indexPath.row == selectedPageIndex
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellWidth, height: tabMenuHeight)
    }
        
    private func getTitleWidth(title: String, font: UIFont) ->CGFloat {
        let label = UILabel()
        label.font = font
        label.text = title
        label.numberOfLines = 1
        label.sizeToFit()
        return label.frame.width + (label.frame.width * 0.2)
    }
}

extension BMPageSegmentView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        selectedPageIndex = indexPath.row
    }
}

extension BMPageSegmentView: UIScrollViewDelegate {
    
    fileprivate func scrollContent(to page: Int) {
        scrollTabMenu(to: page)
    }
    
    fileprivate func scrollTabMenu(to selectedTab: Int) {
        let menuIndexPathToScroll = IndexPath(row: selectedTab, section: 0)
        tabsCollectionView.scrollToItem(at: menuIndexPathToScroll, at: .centeredHorizontally, animated: true)
        tabsCollectionView.reloadData()
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var visibleRect = CGRect()
        visibleRect.origin = tabsCollectionView.contentOffset
        visibleRect.size = tabsCollectionView.bounds.size
        
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        guard let indexPath = tabsCollectionView.indexPathForItem(at: visiblePoint) else { return }
        
        print(indexPath)
    }
}
