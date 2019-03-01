//
//  DisplayPhraseViewController.swift
//  BeamWallet
//
//  Created by Denis on 3/1/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class DisplayPhraseViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    let words = ["garden","water","rifle","century","mutual","foster","wear","fantasy","deer",
                   "attend","approve","maple"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Seed phrase"
        
        collectionView.register(UINib(nibName: "WordCell", bundle: nil), forCellWithReuseIdentifier: WordCell.reuseIdentifier)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: IBAction

    @IBAction func onNext(sender :UIButton) {
        let backItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
        
        let vc = InputPhraseViewController()
        vc.words = words
        navigationController?.pushViewController(vc, animated: true)
    }
}


extension DisplayPhraseViewController : UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return words.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: WordCell.reuseIdentifier,
                                                      for: indexPath) as! WordCell)
            .configured(with: (word: words[indexPath.row], number: String(indexPath.row+1)))
        return cell
    }
}

extension DisplayPhraseViewController : UICollectionViewDelegateFlowLayout {
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
