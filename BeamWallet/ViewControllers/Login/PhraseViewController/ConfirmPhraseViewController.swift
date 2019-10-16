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
    @IBOutlet private var nextButton: UIButton!
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var stackHeight: NSLayoutConstraint!
    
    public var increaseSecutirty = false
    
    override var isUppercasedTitle: Bool {
        get {
            return true
        }
        set {
            super.isUppercasedTitle = true
        }
    }
    
    private var inputWords = [BMWord]()
    private var maxWords = 6
    
    private var words: [String] = [] {
        didSet {
            let shuffled = words.shuffled()
            
            for word in shuffled {
                if let index = words.firstIndex(of: word) {
                    var added = false
                    
                    for inWord in inputWords {
                        if inWord.index == index {
                            added = true
                        }
                    }
                    
                    if !added {
                        inputWords.append(BMWord(String.empty(), index: UInt(index), correct: false))
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: false)
        
        title = Localizable.shared.strings.confirm_seed
        
        if Device.isZoomed {
            if Device.screenType == .iPhones_Plus {
                mainStack?.spacing = 50
            }
            else {
                mainStack?.spacing = 30
            }
        }
        else if Device.screenType == .iPhones_5 {
            stackHeight.constant = 250
            mainStack?.spacing = 50
        }
        else {
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
        if !increaseSecutirty {
            confirmAlert(title: Localizable.shared.strings.seed_back_title, message: Localizable.shared.strings.seed_back_text, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.generate, cancelHandler: { _ in
                
            }) { _ in
                self.back()
            }
        }
        else {
            back()
        }
    }
    
    @IBAction func onNext(sender: UIButton) {
        if increaseSecutirty {
            OnboardManager.shared.makeSecure()
            
            if let viewControllers = self.navigationController?.viewControllers {
                for vc in viewControllers {
                    if vc is WalletViewController {
                        navigationController?.popToViewController(vc, animated: true)
                    }
                    else if vc is SettingsViewController {
                        navigationController?.popToViewController(vc, animated: true)
                    }
                }
            }
        }
        else {
            let vc = CreateWalletPasswordViewController()
                .withPhrase(phrase: words.joined(separator: ";"))
            pushViewController(vc: vc)
        }
    }
}

// MARK: UICollectionViewDataSource

extension ConfirmPhraseViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return maxWords
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: InputWordCell.reuseIdentifier,
                                                       for: indexPath) as! InputWordCell)
            .configured(with: inputWords[indexPath.row], delegate: self)
        return cell
    }
}

// MARK: InputWordCellCellDelegate Handling

extension ConfirmPhraseViewController: InputWordCellCellDelegate {
    func updateInputValue(path: Int, text: String) {
        let index = inputWords[path].index
        
        inputWords[path].value = text
        
        inputWords[path].correct = (words[Int(index)] == text)
    }
    
    func textValueCellDidBeginEditing(_ sender: InputWordCell, _ text: String) {}
    
    func textValueCellReturn(_ sender: InputWordCell, _ text: String) {
        if let path = collectionView.indexPath(for: sender) {
            updateInputValue(path: path.row, text: text)
            
            // find next field
            
            if let cell = collectionView.cellForItem(at: IndexPath(row: path.row + 1, section: 0)) as? InputWordCell {
                cell.startEditing()
            }
            else {
                view.endEditing(true)
            }
        }
    }
    
    func textValueCellDidEndEditing(_ sender: InputWordCell, _ text: String) {
        if let path = collectionView.indexPath(for: sender) {
            updateInputValue(path: path.row, text: text)
            
            collectionView.reloadItems(at: [path])
            
            // correct
            var corretPhrase = true
            for i in 0 ... maxWords - 1 {
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
