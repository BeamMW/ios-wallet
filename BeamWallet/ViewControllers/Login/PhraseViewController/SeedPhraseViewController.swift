//
// SeedPhraseViewController.swift
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

class SeedPhraseViewController: BaseViewController {
    enum EventType {
        case display
        case confirm
        case restore
        case intro
    }
    
    private var collectionView: UICollectionView!
    
    private var event: EventType!
    
    private var words = [String]()
    private var inputWords = [BMWord]()
    private var confirmCountWords = 6
    
    public var increaseSecutirty = false
    
    init(event: EventType, words: [String]?) {
        super.init(nibName: nil, bundle: nil)
        
        self.event = event
        
        if let w = words {
            self.words = w
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboardWhenTappedAround()
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 50, left: 15, bottom: 50, right: 15)
        
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.register(UINib(nibName: WordCell.nib, bundle: nil), forCellWithReuseIdentifier: WordCell.reuseIdentifier)
        collectionView.register(UINib(nibName: InputWordCell.nib, bundle: nil), forCellWithReuseIdentifier: InputWordCell.reuseIdentifier)
        collectionView.register(UINib(nibName: SeedIntroCell.nib, bundle: nil), forCellWithReuseIdentifier: SeedIntroCell.reuseIdentifier)
        collectionView.register(UINib(nibName: CollectionTextHeader.nib, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CollectionTextHeader.reuseIdentifier)
        collectionView.register(UINib(nibName: CollectionButtonFooter.nib, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: CollectionButtonFooter.reuseIdentifier)
        
        collectionView.backgroundColor = UIColor.main.marine
        collectionView.delegate = self
        collectionView.dataSource = self
        
        view.addSubview(collectionView)
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: false)
        
        switch event {
        case .display:
            title = Localizable.shared.strings.seed_prhase
            if Settings.sharedManager().target != Mainnet {
                let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
                view.addGestureRecognizer(lpgr)
            }
        case .confirm:
            
            if !increaseSecutirty {
                addCustomBackButton(target: self, selector: #selector(onNavigationBack))
            }
            
            title = Localizable.shared.strings.confirm_seed
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
        case .restore:
            title = Localizable.shared.strings.restore_wallet_title
            for i in 0 ... 11 {
                inputWords.append(BMWord(String.empty(), index: UInt(i), correct: false))
            }
        case .intro:
            title = Localizable.shared.strings.seed_prhase
        default:
            break
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let y = navigationBarOffset - (Device.isXDevice ? 0 : 30)
        collectionView.frame = CGRect(x: 0, y: y, width: view.bounds.width, height: view.bounds.size.height - y)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        switch event {
        case .display, .restore:
            NotificationCenter.default.addObserver(self, selector: #selector(didTakeScreenshot), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
            
            if !increaseSecutirty {
                let phrase = MnemonicModel.generatePhrase()
                words = phrase.components(separatedBy: ";")
            }
        default:
            break
        }
        
        collectionView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func didTakeScreenshot() {
        if event == .restore {
            var shouldDisplayAlert = false
            for i in 0 ... confirmCountWords - 1 {
                if inputWords[i].correct {
                    shouldDisplayAlert = true
                    break
                }
            }
            if shouldDisplayAlert {
                alert(message: Localizable.shared.strings.seed_capture_warning)
            }
        }
        else {
            alert(message: Localizable.shared.strings.seed_capture_warning)
        }
    }
    
    // MARK: - Actions
    
    @objc private func onNext() {
        if event == .display {
            if increaseSecutirty, !OnboardManager.shared.isSkipedSeed() {
                back()
            }
            else {
                confirmAlert(title: Localizable.shared.strings.save_seed_title, message: Localizable.shared.strings.save_seed_info, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.done, cancelHandler: { _ in
                    
                }) { _ in
                    let vc = SeedPhraseViewController(event: .confirm, words: self.words)
                    vc.increaseSecutirty = self.increaseSecutirty
                    self.pushViewController(vc: vc)
                }
            }
        }
        else if event == .confirm {
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
                let vc = CreateWalletPasswordViewController().withPhrase(phrase: words.joined(separator: ";"))
                pushViewController(vc: vc)
            }
        }
        else if event == .restore {
            alert(title: Localizable.shared.strings.info_restore_title, message: Localizable.shared.strings.info_restore_text, button: Localizable.shared.strings.understand) { [weak self] _ in
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
        else if event == .intro {
            let vc = SeedPhraseViewController(event: .display, words: nil)
            pushViewController(vc: vc)
        }
    }
    
    @objc private func onBack() {
        if event == .display {
            if !increaseSecutirty {
                OnboardManager.shared.onSkipSeed(isSkiped: true)
                let vc = CreateWalletPasswordViewController()
                    .withPhrase(phrase: words.joined(separator: ";"))
                pushViewController(vc: vc)
            }
            else {
                back()
            }
        }
        else if event == .restore, Settings.sharedManager().target != Mainnet {
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
                
                collectionView.reloadData()
            }
        }
    }
    
    @objc private func onNavigationBack() {
        confirmAlert(title: Localizable.shared.strings.seed_back_title, message: Localizable.shared.strings.seed_back_text, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.generate, cancelHandler: { _ in
            
        }) { _ in
            self.back()
        }
    }
    
    @objc private func handleLongPress(sender: UIGestureRecognizer) {
        if sender.state == .began {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
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
    }
    
    // MARK: -
    
    func isCorrectPhrase() -> Bool {
        var corretPhrase = true
        for i in 0 ... confirmCountWords - 1 {
            if inputWords[i].value.isEmpty {
                corretPhrase = false
                break
            }
            else if !inputWords[i].correct {
                corretPhrase = false
                break
            }
        }
        return corretPhrase
    }
    
    func introOptions(row: Int) -> (text: String, image: UIImage?) {
        switch row {
        case 0:
            return (text: Localizable.shared.strings.intro_seed_1, image: UIImage(named: "iconEye"))
        case 1:
            return (text: Localizable.shared.strings.intro_seed_2, image: UIImage(named: "iconPassword"))
        case 2:
            return (text: Localizable.shared.strings.intro_seed_3, image: UIImage(named: "iconCopy"))
        default:
            return (text: "", image: UIImage())
        }
    }
    
    func introHeight(row: Int) -> Int {
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let w = collectionView.frame.size.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right - 75
        return Int(introOptions(row: row).text.height(withConstrainedWidth: w, font: RegularFont(size: 15))) + 30
    }
}

// MARK: UICollectionViewDataSource

extension SeedPhraseViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch event {
        case .confirm:
            return confirmCountWords
        case .restore:
            return inputWords.count
        case .intro:
            return 3
        default:
            return words.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch event {
        case .display:
            let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: WordCell.reuseIdentifier,
                                                           for: indexPath) as! WordCell)
                .configured(with: (word: words[indexPath.row], number: String(indexPath.row + 1)))
            return cell
        case .intro:
            let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: SeedIntroCell.reuseIdentifier, for: indexPath) as! SeedIntroCell)
                .configured(with: introOptions(row: indexPath.row))
            return cell
        default:
            let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: InputWordCell.reuseIdentifier, for: indexPath) as! InputWordCell)
                .configured(with: inputWords[indexPath.row], delegate: self)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier:
                CollectionButtonFooter.reuseIdentifier, for: indexPath) as! CollectionButtonFooter
            footer.setData(event: event)
            footer.btn1.removeTarget(nil, action: nil, for: .allEvents)
            footer.btn2.removeTarget(nil, action: nil, for: .allEvents)
            footer.btn1.addTarget(self, action: #selector(onNext), for: .touchUpInside)
            footer.btn2.addTarget(self, action: #selector(onBack), for: .touchUpInside)
            
            if event != .display, event != .intro {
                footer.btn1.isEnabled = isCorrectPhrase()
            }
            else if event == .display, increaseSecutirty, !OnboardManager.shared.isSkipedSeed() {
                footer.btn2.isHidden = true
                footer.btn1.setTitle(Localizable.shared.strings.done.lowercased(), for: .normal)
                footer.btn1.setImage(IconDoneBlue(), for: .normal)
            }
            
            return footer
        }
        else {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier:
                CollectionTextHeader.reuseIdentifier, for: indexPath) as! CollectionTextHeader
            header.setData(event: event)
            return header
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let indexPath = IndexPath(row: 0, section: section)
        let headerView = self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader, at: indexPath)
        return headerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: UIView.layoutFittingExpandedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.width, height: 120)
    }
}

// MARK: UICollectionViewDelegateFlowLayout

extension SeedPhraseViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let noOfCellsInRow = (event == .intro) ? 1 : 2
        
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        
        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))
        
        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(noOfCellsInRow))
        
        let height = (event == .intro) ? introHeight(row: indexPath.row) : 38
        
        return CGSize(width: size, height: height)
    }
}

// MARK: InputWordCellCellDelegate Handling

extension SeedPhraseViewController: InputWordCellCellDelegate {
    func updateInputValue(path: Int, text: String) {
        if event == .restore {
            inputWords[path].value = text
            inputWords[path].correct = MnemonicModel.isValidWord(text)
        }
        else {
            let index = inputWords[path].index
            inputWords[path].value = text
            inputWords[path].correct = (words[Int(index)] == text)
        }
    }
    
    func textValueCellDidBeginEditing(_ sender: InputWordCell, _ text: String) {
        if let path = collectionView.indexPath(for: sender) {
            collectionView.scrollToItem(at: path, at: .bottom, animated: true)
        }
    }
    
    func textValueCellReturn(_ sender: InputWordCell, _ text: String) {
        if let path = collectionView.indexPath(for: sender) {
            updateInputValue(path: path.row, text: text)
            
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
            
            let footer = collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionFooter, at: path) as! CollectionButtonFooter
            
            if event != .display {
                footer.btn1.isEnabled = isCorrectPhrase()
            }
        }
    }
}

extension SeedPhraseViewController {
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        collectionView.contentInset = UIEdgeInsets.zero
    }
}
