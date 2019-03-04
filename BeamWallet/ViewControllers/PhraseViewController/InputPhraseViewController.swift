//
//  InputPhraseViewController.swift
//  BeamWallet
//
//  Created by Denis on 3/2/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class InputPhraseViewController: BaseWizardViewController {

    private var inputWords = [BMWord]()

    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var nextButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Seed phrase"
        
        for i in 0 ... 11 {
            inputWords.append(BMWord(word: "", index: i, correct: false))
        }
        
        collectionView.register(UINib(nibName: InputWordCell.nib, bundle: nil), forCellWithReuseIdentifier: InputWordCell.reuseIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if Device.screenType == .iPhones_5_5s_5c_SE {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        }
       
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if Device.screenType == .iPhones_5_5s_5c_SE {
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification , object: nil)
        }
    }
}

// MARK: UICollectionViewDataSource
extension InputPhraseViewController : UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return inputWords.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: InputWordCell.reuseIdentifier,
                                                       for: indexPath) as! InputWordCell)
            .configured(with: inputWords[indexPath.row],delegate: self)
        return cell
    }
}

// MARK: InputWordCellCellDelegate Handling
extension InputPhraseViewController : InputWordCellCellDelegate {
    
    func updateInputValue(path:Int, text:String) {
        inputWords[path].value = text
        inputWords[path].correct = MnemonicModel.isValidWord(text)
    }
    
    func textValueCellReturn(_ sender: InputWordCell, _ text:String) {
        if let path = collectionView.indexPath(for: sender)
        {
            updateInputValue(path: path.row, text: text)
            
            //find next field
            for i in 0 ... inputWords.count - 1 {
                if inputWords[i].value.isEmpty {
                    let cell = collectionView.cellForItem(at: IndexPath(row: i, section: 0)) as! InputWordCell
                    cell.startEditing()
                    
                    break;
                }
            }
        }
    }
    
    func textValueCellDidEndEditing(_ sender: InputWordCell, _ text: String) {
        if let path = collectionView.indexPath(for: sender)
        {
            updateInputValue(path: path.row, text: text)
            
            collectionView.reloadItems(at: [path])
            
            //correct
            var corretPhrase = true
            for word in inputWords  {
                if word.value.isEmpty {
                    corretPhrase = false
                    break
                }
                else if !word.correct {
                    corretPhrase = false
                    break
                }
            }
            
            nextButton.isEnabled = corretPhrase
        }
    }
}

// MARK: Keyboard Handling
extension InputPhraseViewController {
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        self.collectionView.contentInset = UIEdgeInsets.zero
    }
}

