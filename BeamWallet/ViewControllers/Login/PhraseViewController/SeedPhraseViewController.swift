//
//  SeedPhraseViewController.swift
//  BeamWallet
//
//  Created by Denis on 10/18/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class SeedPhraseViewController: BaseViewController {
    enum EventType {
        case display
        case increaseSecurity
        case confirm
        case restore
    }
    
    private var collectionView: UICollectionView!
    
    private var event: EventType!
    
    private var words = [String]()
    private var phrase: String!
    
    init(event: EventType, words: String?) {
        super.init(nibName: nil, bundle: nil)
        
        self.event = event
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override var isUppercasedTitle: Bool {
        get {
            return true
        }
        set {
            super.isUppercasedTitle = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 50, left: 0, bottom: 50, right: 0)
        
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.register(UINib(nibName: WordCell.nib, bundle: nil), forCellWithReuseIdentifier: WordCell.reuseIdentifier)
        collectionView.register(UINib(nibName: CollectionTextHeader.nib, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CollectionTextHeader.reuseIdentifier)
        collectionView.register(UINib(nibName: CollectionButtonFooter.nib, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: CollectionButtonFooter.reuseIdentifier)
        
        collectionView.backgroundColor = UIColor.main.marine
        collectionView.delegate = self
        collectionView.dataSource = self
        
        view.addSubview(collectionView)
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: false)
        
        title = Localizable.shared.strings.seed_prhase
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        switch event {
        case .display:
            phrase = MnemonicModel.generatePhrase()
            words = phrase.components(separatedBy: ";")
        case .increaseSecurity:
            if let savedPhrase = OnboardManager.shared.getSeed() {
                phrase = savedPhrase
                words = phrase.components(separatedBy: ";")
            }
        default:
            break
        }
        
        collectionView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let y = navigationBarOffset - 30
        collectionView.frame = CGRect(x: 15, y: y, width: view.bounds.width - 30, height: view.bounds.size.height - y)
    }
}

// MARK: UICollectionViewDataSource

extension SeedPhraseViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return words.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: WordCell.reuseIdentifier,
                                                       for: indexPath) as! WordCell)
            .configured(with: (word: words[indexPath.row], number: String(indexPath.row + 1)))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier:
                CollectionButtonFooter.reuseIdentifier, for: indexPath) as! CollectionButtonFooter
            
            return footer
        }
        else {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier:
                CollectionTextHeader.reuseIdentifier, for: indexPath) as! CollectionTextHeader
            header.setData(event: event)
            return header
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let indexPath = IndexPath(row: 0, section: section)
        let headerView = self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader, at: indexPath)
        return headerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: UIView.layoutFittingExpandedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let indexPath = IndexPath(row: 0, section: section)
        let headerView = self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader, at: indexPath)
        return headerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: UIView.layoutFittingExpandedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
    }
}

// MARK: UICollectionViewDelegateFlowLayout

extension SeedPhraseViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let noOfCellsInRow = 2
        
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        
        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))
        
        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(noOfCellsInRow))
        
        return CGSize(width: size, height: 38)
    }
}
