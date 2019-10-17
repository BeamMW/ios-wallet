//
// InputPhraseViewController.swift
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

class InputPhraseViewController: BaseWizardViewController {
    
    private var inputWords = [BMWord]()
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var scrollView: UIScrollView!

    @IBOutlet private weak var testNetNextButton: UIButton!
    @IBOutlet private weak var testNetNextView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = Localizable.shared.strings.restore_wallet_title
        
        nextButton.isEnabled = false
        testNetNextButton.isEnabled = false

        for i in 0 ... 11 {
            inputWords.append(BMWord(String.empty(), index: UInt(i), correct: false))
        }

        scrollView.keyboardDismissMode = .interactive
        collectionView.keyboardDismissMode = .interactive
        collectionView.register(UINib(nibName: InputWordCell.nib, bundle: nil), forCellWithReuseIdentifier: InputWordCell.reuseIdentifier)
        
        if Settings.sharedManager().target == Testnet || Settings.sharedManager().target == Masternet {
            testNetNextView.isHidden = false
            nextButton.isHidden = true
        }
        else{
            testNetNextView.isHidden = true
            nextButton.isHidden = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didTakeScreenshot), name: UIApplication.userDidTakeScreenshotNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
       
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification , object: nil)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @objc private func didTakeScreenshot() {
        var showAlert = false
        
        for word in inputWords  {
            if !word.value.isEmpty && word.correct  {
                showAlert = true
                break
            }
        }
        
        if showAlert {
            self.alert(message: Localizable.shared.strings.seed_capture_warning)
        }
    }
    
    // MARK: IBAction
    
    @IBAction func onPaste(sender :UIButton) {
        if let string = UIPasteboard.general.string {
            let s1 = string.split(separator: ";")
            let s2 = string.split(separator: "\n")

            if s1.count > 2 {
                inputWords.removeAll()

                var i = 0
                for s in s1 {
                    inputWords.append(BMWord(String(s), index: UInt(i), correct: true))
                    i = i + 1
                }
            }
            else if s2.count > 2 {
                inputWords.removeAll()
                
                var i = 0
                for s in s2 {
                    if let w = s.split(separator: " ").last {
                        inputWords.append(BMWord(String(w), index: UInt(i), correct: true))
                        i = i + 1
                    }
                }
            }
            
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
            testNetNextButton.isEnabled = corretPhrase
            
            collectionView.reloadData()
        }
    }
    
    @IBAction func onNext(sender :UIButton) {
        self.alert(title: Localizable.shared.strings.info_restore_title, message: Localizable.shared.strings.info_restore_text, button: Localizable.shared.strings.understand) {[weak self] (_ ) in
            guard let strongSelf = self else { return }
            
            var words = [String]()
            
            for w in strongSelf.inputWords {
                words.append(w.value)
            }
            
            let vc = CreateWalletPasswordViewController()
                .withPhrase(phrase: words.joined(separator: ";"))
            strongSelf.pushViewController(vc: vc)
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
    
    func textValueCellDidBeginEditing(_ sender: InputWordCell, _ text: String) {
        let point = collectionView.convert(sender.frame, to: scrollView)
        let y = point.origin.y - scrollView.contentInset.bottom
        if y > 0 && scrollView.contentInset.bottom != 0 {
            scrollView.setContentOffset(CGPoint(x: 0, y: y), animated: true)
        }
    }
    
    func textValueCellReturn(_ sender: InputWordCell, _ text:String) {
        if let path = collectionView.indexPath(for: sender)
        {
            updateInputValue(path: path.row, text: text)

            //find next field
            if let cell = collectionView.cellForItem(at: IndexPath(row: path.row + 1, section: 0)) as? InputWordCell {
                cell.startEditing()
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
            testNetNextButton.isEnabled = corretPhrase
        }
    }
}

// MARK: Keyboard Handling
extension InputPhraseViewController {
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        self.scrollView.contentInset = UIEdgeInsets.zero
    }
}

