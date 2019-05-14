//
// ConfirmPhraseViewController.swift
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

class ConfirmPhraseViewController: BaseWizardViewController {

    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var titleLabel: UILabel!

    private var inputWords = [BMWord]()
    private var maxWords = 6
    
    private var words: [String] = [] {
        didSet{
            let shuffled =  words.shuffled()
            
            for word in shuffled{
                if let index = words.firstIndex(of: word) {
                    var added = false
                    
                    for inWord in inputWords {
                        if inWord.index == index {
                            added = true
                        }
                    }
                    
                    if !added {
                        inputWords.append(BMWord(word: String.empty(), index: index, correct: false))
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = LocalizableStrings.confirm_seed
        
        if Device.isZoomed {
            stackY?.constant = 10
            mainStack?.spacing = 30
        }
        else if Device.screenType == .iPhones_5 {
            mainStack?.spacing = 50
        }
        else{
            mainStack?.spacing = 40
        }
        
        collectionView.register(UINib(nibName: InputWordCell.nib, bundle: nil), forCellWithReuseIdentifier: InputWordCell.reuseIdentifier)
        
        addCustomBackButton(target: self, selector: #selector(onBack))
        
        hideKeyboardWhenTappedAround()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if inputWords[0].value.isEmpty {
            let cell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as! InputWordCell
            cell.startEditing()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
// MARK: IBAction
    @objc private func onBack() {
        self.confirmAlert(title: LocalizableStrings.seed_back_title, message: LocalizableStrings.seed_back_text, cancelTitle: LocalizableStrings.cancel, confirmTitle: LocalizableStrings.generate, cancelHandler: { (_ ) in
            
        }) { (_ ) in
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func onNext(sender :UIButton) {
        let vc = CreateWalletPasswordViewController()
            .withPhrase(phrase: words.joined(separator: ";"))
        pushViewController(vc: vc)
    }
}

// MARK: UICollectionViewDataSource
extension ConfirmPhraseViewController : UICollectionViewDataSource {
    
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


// MARK: InputWordCellCellDelegate Handling
extension ConfirmPhraseViewController : InputWordCellCellDelegate {
    
    func updateInputValue(path:Int, text:String) {
        let index = inputWords[path].index
        
        inputWords[path].value = text
        
        inputWords[path].correct = (words[index!]==text)
    }
    
    func textValueCellReturn(_ sender: InputWordCell, _ text:String) {
        if let path = collectionView.indexPath(for: sender)
        {
            updateInputValue(path: path.row, text: text)
            
            //find next field
            
            if let cell = collectionView.cellForItem(at: IndexPath(row: path.row + 1, section: 0)) as? InputWordCell {
                 cell.startEditing()
            }
            else{
                self.view.endEditing(true)
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
            for i in 0 ... maxWords - 1{
                if inputWords[i].value.isEmpty {
                    corretPhrase = false
                    break
                }
                else if !inputWords[i].correct {
                    corretPhrase = false
                    break
                }
            }
            
            nextButton.isEnabled = corretPhrase
        }
    }
}

extension ConfirmPhraseViewController {
    
    func withWords(words: [String]) -> Self {
        
        self.words = words
        
        return self
    }
}
