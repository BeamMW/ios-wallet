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
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var copyButton: UIButton!

    var words = [String]()
    var phrase:String!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "seed_prhase".localized
        
        collectionView.register(UINib(nibName: WordCell.nib, bundle: nil), forCellWithReuseIdentifier: WordCell.reuseIdentifier)
        
        if Device.isZoomed {
            stackY?.constant = 10
            mainStack?.spacing = 10
        }
        else if Device.screenType == .iPhones_5 {
            mainStack?.spacing = 20
        }
        else if Device.screenType == .iPhones_6 {
            mainStack?.spacing = 30
        }
        else if Device.screenType == .iPhone_XSMax {
            mainStack?.spacing = 110
        }
        
        if Settings.sharedManager().target == Testnet {
            copyButton.isHidden = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        phrase = MnemonicModel.generatePhrase()
        
        words = phrase.components(separatedBy: ";")
        
        self.collectionView.reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didTakeScreenshot), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func didTakeScreenshot() {
        self.alert(message: "seed_capture_warning".localized)
    }
    
// MARK: IBAction
    @IBAction func onCopy(sender :UIButton) {
        var copyPhrase = ""
        var index = 1
        
        for word in words {
            let s = String(index) + ": " + word
            if copyPhrase.isEmpty {
                copyPhrase = s
            }
            else{
                copyPhrase = copyPhrase + "\n" + s
            }
            index = index + 1
        }
        
        UIPasteboard.general.string = copyPhrase
        
        SVProgressHUD.showSuccess(withStatus: "copied_to_clipboard".localized)
        SVProgressHUD.dismiss(withDelay: 1.5)
    }
    
    @IBAction func onNext(sender :UIButton) {
        let alert = UIAlertController(title: "save_seed_title".localized, message: "save_seed_info".localized, preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "done".localized, style: .default, handler: { action in
            let vc = ConfirmPhraseViewController()
                .withWords(words: self.words)
            self.pushViewController(vc: vc)
        })
        alert.addAction(UIAlertAction(title: "cancel".localized, style: .default, handler: nil))
        alert.addAction(ok)


        self.present(alert, animated: true)
    }
}


// MARK: UICollectionViewDataSource
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
