//
// DisplayPhraseViewController.swift
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

class DisplayPhraseViewController: BaseWizardViewController {
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var laterButton: UIButton!
    @IBOutlet private var nextButton: UIButton!
    
    var words = [String]()
    var phrase: String!
    
    public var increaseSecutirty = false
    
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
        
        if AppModel.sharedManager().isLoggedin {
            laterButton.isHidden = true
        }
        
        if increaseSecutirty, !OnboardManager.shared.isSkipedSeed() {
            nextButton.setTitle(Localizable.shared.strings.done, for: .normal)
            nextButton.setImage(IconDoneBlue(), for: .normal)
        }
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: false)
        
        title = Localizable.shared.strings.seed_prhase
        
        collectionView.register(UINib(nibName: WordCell.nib, bundle: nil), forCellWithReuseIdentifier: WordCell.reuseIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !increaseSecutirty {
            phrase = MnemonicModel.generatePhrase()
            words = phrase.components(separatedBy: ";")
        }
        else if let savedPhrase = OnboardManager.shared.getSeed() {
            phrase = savedPhrase
            words = phrase.components(separatedBy: ";")
        }
        
        collectionView.reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didTakeScreenshot), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func didTakeScreenshot() {
        alert(message: Localizable.shared.strings.seed_capture_warning)
    }
    
    // MARK: IBAction
    
    @IBAction func onCopy(sender: UIButton) {
        var copyPhrase = ""
        var index = 1
        
        for word in words {
            let s = String(index) + ": " + word
            if copyPhrase.isEmpty {
                copyPhrase = s
            }
            else {
                copyPhrase = copyPhrase + "\n" + s
            }
            index = index + 1
        }
        
        UIPasteboard.general.string = copyPhrase
        
        ShowCopied()
    }
    
    @IBAction func onNext(sender: UIButton) {
        if increaseSecutirty, !OnboardManager.shared.isSkipedSeed() {
            if let viewControllers = self.navigationController?.viewControllers {
                for vc in viewControllers {
                    if vc is SettingsViewController {
                        navigationController?.popToViewController(vc, animated: true)
                    }
                }
            }
            
            return
        }
        else if !increaseSecutirty {
            OnboardManager.shared.onSkipSeed(isSkiped: false)
        }
        
        confirmAlert(title: Localizable.shared.strings.save_seed_title, message: Localizable.shared.strings.save_seed_info, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.done, cancelHandler: { _ in
            
        }) { _ in
            let vc = ConfirmPhraseViewController()
                .withWords(words: self.words)
            vc.increaseSecutirty = self.increaseSecutirty
            self.pushViewController(vc: vc)
        }
    }
    
    @IBAction func onLater(sender: UIButton) {
        OnboardManager.shared.onSkipSeed(isSkiped: true)

        let vc = CreateWalletPasswordViewController()
            .withPhrase(phrase: words.joined(separator: ";"))
        pushViewController(vc: vc)
    }
}

// MARK: UICollectionViewDataSource

extension DisplayPhraseViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return words.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: WordCell.reuseIdentifier,
                                                       for: indexPath) as! WordCell)
            .configured(with: (word: words[indexPath.row], number: String(indexPath.row + 1)))
        return cell
    }
}
