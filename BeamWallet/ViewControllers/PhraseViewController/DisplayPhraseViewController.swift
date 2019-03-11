//
//  DisplayPhraseViewController.swift
//  BeamWallet
//
// 3/1/19.
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

    var words = [String]()
    var phrase:String!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Seed phrase"
        
        collectionView.register(UINib(nibName: WordCell.nib, bundle: nil), forCellWithReuseIdentifier: WordCell.reuseIdentifier)
        
        if Device.screenType == .iPhones_5_5s_5c_SE {
            mainStack?.spacing = 20
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        phrase = MnemonicModel.generatePhrase()
        
        words = phrase.components(separatedBy: ";")
        
        self.collectionView.reloadData()
    }
    
// MARK: IBAction
    @IBAction func onCopy(sender :UIButton) {
        UIPasteboard.general.string = phrase
        
        SVProgressHUD.showSuccess(withStatus: "copied to clipboard")
        SVProgressHUD.dismiss(withDelay: 1.5)
    }
    
    @IBAction func onNext(sender :UIButton) {
        let alert = UIAlertController(title: "Save seed phrase", message: "Please write the seed phrase down. Do not screenshot it and save it in your photo gallery. It makes the phrase prone to cyber attacks and, therefore, less secure.", preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "Done", style: .default, handler: { action in
            let vc = ConfirmPhraseViewController()
                .withWords(words: self.words)
            self.pushViewController(vc: vc)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
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
