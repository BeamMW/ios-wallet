//
//  InputPhraseViewController.swift
//  BeamWallet
//
//  Created by Denis on 3/1/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class InputPhraseViewController: UIViewController {

    @IBOutlet private weak var nextButton: UIButton!
    
    @IBOutlet private weak var stackWidth: NSLayoutConstraint!
    @IBOutlet private weak var stackY: NSLayoutConstraint!
    @IBOutlet private weak var mainStack: UIStackView!
    
    @IBOutlet private weak var collectionView: UICollectionView!

    private var inputWords = [BMWord]()
    private let maxWords = 6
    
    public var words: [String] = [] {
        didSet{
            let shuffled = words.shuffled()
            
            for word in shuffled{
                if let index = words.firstIndex(of: word) {
                    inputWords.append(BMWord(word: "", index: index, correct: false))
                }
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Seed phrase"
                
        collectionView.register(UINib(nibName: "InputWordCell", bundle: nil), forCellWithReuseIdentifier: InputWordCell.reuseIdentifier)
        
        if Device.screenType == .iPhones_5_5s_5c_SE {
            stackWidth.constant = 290
            mainStack.spacing = 25
            stackY.constant = 15
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: IBAction
    
    @IBAction func onNext(sender :UIButton) {
        let backItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
        
        let vc = CreateWalletPasswordViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension InputPhraseViewController : UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return maxWords
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: InputWordCell.reuseIdentifier,
                                                       for: indexPath) as! InputWordCell)
        .configured(with: inputWords[indexPath.row],delegate: self)
        return cell
    }
}

extension InputPhraseViewController : UICollectionViewDelegateFlowLayout {
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

extension InputPhraseViewController : InputWordCellCellDelegate {
    func textValueCellDidEndEditing(_ sender: InputWordCell, _ text: String) {
        if let path = collectionView.indexPath(for: sender)
        {
            let index = inputWords[path.row].index
            
            inputWords[path.row].value = text
            
            inputWords[path.row].correct = (words[index!]==text)
            
            collectionView.reloadItems(at: [path])
            
            //find next field
            var corretPhrase = true
            for i in 0 ... maxWords - 1{
                if inputWords[i].value.isEmpty {
                    corretPhrase = false
                    
                    let cell = collectionView.cellForItem(at: IndexPath(row: i, section: 0)) as! InputWordCell
                    cell.startEditing()
                    
                    break;
                }
                else if !inputWords[i].correct {
                    corretPhrase = false
                }
            }
            
            nextButton.isEnabled = corretPhrase
        }
    }
}
