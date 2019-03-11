//
//  InputPhraseViewController.swift
//  BeamWallet
//
// 3/2/19.
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
    
    // MARK: IBAction
    @IBAction func onNext(sender :UIButton) {
        var words = [String]()
        
        for w in inputWords {
            words.append(w.value)
        }
        
        let vc = CreateWalletPasswordViewController()
            .withPhrase(phrase: words.joined(separator: ";"))
        pushViewController(vc: vc)
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

