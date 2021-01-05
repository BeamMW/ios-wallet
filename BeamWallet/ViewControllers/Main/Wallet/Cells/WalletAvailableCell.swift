//
//  WalletAvailableCell.swift
//  BeamWallet
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

protocol WalletAvailableCellDelegate: AnyObject {
    func onExpandAvailable()
    func onDidChangeSelectedState(state:StatusViewModel.SelectedState)
    func onMoreDetails()
}

class WalletAvailableCell: BaseCell {

    weak var delegate: WalletAvailableCellDelegate?

    @IBOutlet weak private var pageView: UIPageControl!

    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var mainButton: UIButton!

    @IBOutlet weak private var arrowIcon: UIImageView!

    @IBOutlet weak private var buttonsStackView: UIStackView!
    @IBOutlet weak private var availableButton: UIButton!
    @IBOutlet weak private var maturingButton: UIButton!
    @IBOutlet weak private var maxPrivactTopButtonButton: UIButton!

    @IBOutlet weak private var availableView: UIView!
    @IBOutlet weak private var maturingView: UIView!
    @IBOutlet weak private var maxPrivacyView: UIView!

    @IBOutlet weak private var balanceLabel: UILabel!
    @IBOutlet weak private var balanceIcon: UIImageView!
    
    @IBOutlet weak private var maturingLabel: UILabel!
    
    @IBOutlet weak private var maxPrivacyLabel: UILabel!
    
    @IBOutlet weak private var secondAvailableLabel: UILabel!
    @IBOutlet weak private var secondMaturingLabel: UILabel!
    @IBOutlet weak private var secondMaxPrivacyLabel: UILabel!

    @IBOutlet weak private var moreDetailsButton: UIButton!

    private var selectedState = StatusViewModel.SelectedState.available
    private var availableMaturing = false
    private var availableMaxPrivacy = false

    private var isExpand = true

    public static func hideHeight() -> CGFloat {
        return 78
    }
    
    public static func singleHeight() -> CGFloat {
        return 140.0
    }
    
    public static func secondHeight() -> CGFloat {
        return 150.0
    }
    
    public static func maturingHeight() -> CGFloat {
        return 170.0
    }
        
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        moreDetailsButton.setTitleColor(UIColor.main.brightTeal, for: .normal)
        
        secondMaturingLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        secondAvailableLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        secondMaxPrivacyLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey

        secondMaturingLabel.font = RegularFont(size: 14)
        secondAvailableLabel.font = RegularFont(size: 14)
        secondMaxPrivacyLabel.font = RegularFont(size: 14)

        
        mainView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        
        mainButton.setBackgroundImage(UIImage.fromColor(color: UIColor.black.withAlphaComponent(0.3)), for: .highlighted)
        
        let avaiableString = NSMutableAttributedString(string: Localizable.shared.strings.available.uppercased())
        avaiableString.addAttribute(NSAttributedString.Key.kern, value: CGFloat(1.5), range: NSRange(location: 0, length: avaiableString.string.count))
        avaiableString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.blueyGrey, range: NSRange(location: 0, length: avaiableString.string.count))

        let maturingString = NSMutableAttributedString(string: Localizable.shared.strings.maturing.uppercased())
        maturingString.addAttribute(NSAttributedString.Key.kern, value: CGFloat(1.5), range: NSRange(location: 0, length: maturingString.string.count))
        maturingString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.blueyGrey, range: NSRange(location: 0, length: maturingString.string.count))

        let maxString = NSMutableAttributedString(string: Localizable.shared.strings.max_privacy.uppercased())
        maxString.addAttribute(NSAttributedString.Key.kern, value: CGFloat(1.5), range: NSRange(location: 0, length: maxString.string.count))
        maxString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.blueyGrey, range: NSRange(location: 0, length: maxString.string.count))
        
        availableButton.setAttributedTitle(avaiableString, for: .normal)
        maturingButton.setAttributedTitle(maturingString, for: .normal)
        maxPrivactTopButtonButton.setAttributedTitle(maxString, for: .normal)

        arrowIcon.image = IconDownArrow()
    }
    
    @IBAction func onExpand(sender :UIButton) {
        self.delegate?.onExpandAvailable()
    }
    
    @IBAction func onSelectPage(sender :UIPageControl) {
        selectedState = StatusViewModel.SelectedState(rawValue: sender.currentPage) ?? .available
        delegate?.onDidChangeSelectedState(state: selectedState)
        didSelectState(animation: true)
    }
    
    @IBAction func onMoreDetails(sender :UIButton) {
        delegate?.onMoreDetails()
    }
    
    @IBAction func onStackButtons(sender :UIButton) {
        if selectedState != .maturing && sender == maturingButton {
            selectedState = .maturing
            delegate?.onDidChangeSelectedState(state: selectedState)
            didSelectState(animation: true)
        }
        else if selectedState != .available && sender == availableButton {
            selectedState = .available
            delegate?.onDidChangeSelectedState(state: selectedState)
            didSelectState(animation: true)
        }
        else if selectedState != .maxPrivacy && sender == maxPrivactTopButtonButton {
            selectedState = .maxPrivacy
            delegate?.onDidChangeSelectedState(state: selectedState)
            didSelectState(animation: true)
        }
    }
    
    
    @objc private func onSwipe(sender:UISwipeGestureRecognizer) {
        if isExpand {
            if sender.direction == .right {
                if selectedState == .maxPrivacy {
                    selectedState = .available
                    delegate?.onDidChangeSelectedState(state: selectedState)
                    didSelectState(animation: true)
                }
                else if selectedState == .maturing {
                    if availableMaxPrivacy {
                        selectedState = .maxPrivacy
                        delegate?.onDidChangeSelectedState(state: selectedState)
                        didSelectState(animation: true)
                    }
                    else {
                        selectedState = .available
                        delegate?.onDidChangeSelectedState(state: selectedState)
                        didSelectState(animation: true)
                    }
                }
            }
            else if sender.direction == .left {
                if selectedState == .available {
                    if availableMaxPrivacy {
                        selectedState = .maxPrivacy
                        delegate?.onDidChangeSelectedState(state: selectedState)
                        didSelectState(animation: true)
                    }
                    else if availableMaturing {
                        selectedState = .maturing
                        delegate?.onDidChangeSelectedState(state: selectedState)
                        didSelectState(animation: true)
                    }
                }
                else if selectedState == .maxPrivacy {
                    if availableMaturing {
                        selectedState = .maturing
                        delegate?.onDidChangeSelectedState(state: selectedState)
                        didSelectState(animation: true)
                    }
                }
            }
        }
    }
    
    private func expand(expand:Bool, animation:Bool) {        
        UIView.animate(withDuration: animation ? 0.3 : 0) {
            self.maturingView.isHidden = (expand ? false : true)
            self.availableView.isHidden = (expand ? false : true)
            self.maxPrivacyView.isHidden = (expand ? false : true)
            self.pageView.alpha = (expand ? 1 : 0)
            self.buttonsStackView.isUserInteractionEnabled = (expand ? true : false)
            self.arrowIcon.transform = CGAffineTransform(rotationAngle: expand ? CGFloat(0 * Double.pi/180) : CGFloat(-90 * Double.pi/180))
        }
    }
    
    private func didSelectState(animation:Bool) {
        let size = self.availableButton.titleLabel?.font.pointSize ?? 14

        UIView.animate(withDuration: animation ? 0.3 : 0, animations: {
            if self.selectedState == .available {
                self.moreDetailsButton.isHidden = true
                
                self.pageView.currentPage = 0
                
                self.maturingView.alpha = 0
                self.maxPrivacyView.alpha = 0
                self.availableView.alpha = 1
                
                self.availableButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.maturingButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                self.maxPrivactTopButtonButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }
            else if self.selectedState == .maturing {
                self.moreDetailsButton.isHidden = true

                self.pageView.currentPage = (self.availableMaxPrivacy) ? 2 : 1
                
                self.maturingView.alpha = 1
                self.availableView.alpha = 0
                self.maxPrivacyView.alpha = 0

                self.maturingButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.availableButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                self.maxPrivactTopButtonButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }
            else if self.selectedState == .maxPrivacy {
                self.moreDetailsButton.isHidden = false

                self.pageView.currentPage = 1
                
                self.maturingView.alpha = 0
                self.availableView.alpha = 0
                self.maxPrivacyView.alpha = 1
                
                self.maxPrivactTopButtonButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.availableButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                self.maturingButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }
        }) { (_ ) in
            if self.selectedState == .available {
                self.moreDetailsButton.isHidden = true

                self.availableButton.titleLabel?.font = BoldFont(size: size)
                self.maturingButton.titleLabel?.font = RegularFont(size: size)
                self.maxPrivactTopButtonButton.titleLabel?.font = RegularFont(size: size)
            }
            else if self.selectedState == .maxPrivacy {
                self.moreDetailsButton.isHidden = false

                self.maxPrivactTopButtonButton.titleLabel?.font = BoldFont(size: size)
                self.availableButton.titleLabel?.font = RegularFont(size: size)
                self.maturingButton.titleLabel?.font = RegularFont(size: size)
            }
            else{
                self.moreDetailsButton.isHidden = true

                self.maturingButton.titleLabel?.font = BoldFont(size: size)
                self.availableButton.titleLabel?.font = RegularFont(size: size)
                self.maxPrivactTopButtonButton.titleLabel?.font = RegularFont(size: size)
            }
        }
    }
}

extension WalletAvailableCell: Configurable {
    
    func configure(with options: (expand: Bool, status:BMWalletStatus?, selectedState:StatusViewModel.SelectedState, avaiableMaturing:Bool, avaiableMaxPrivacy:Bool)) {
        
        mainView.gestureRecognizers?.removeAll()

        selectedState = options.selectedState
        availableMaturing = options.avaiableMaturing
        availableMaxPrivacy = options.avaiableMaxPrivacy

        isExpand = options.expand
        
        
        if options.selectedState == .maxPrivacy {
            moreDetailsButton.isHidden = false
        }
        else {
            moreDetailsButton.isHidden = true
        }
        
        if availableMaturing || availableMaxPrivacy {
            let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe))
            swipeLeft.direction = .left
            mainView.addGestureRecognizer(swipeLeft)
            
            let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe))
            swipeRight.direction = .right
            mainView.addGestureRecognizer(swipeRight)
            
            pageView.isHidden = false
            pageView.numberOfPages = (availableMaxPrivacy && availableMaturing) ? 3 : 2

            maturingButton.isHidden = !availableMaturing
            maxPrivactTopButtonButton.isHidden = !availableMaxPrivacy
        }
        else{
            pageView.isHidden = true
            maturingButton.isHidden = true
            maxPrivactTopButtonButton.isHidden = true
        }
        
        if let status = options.status {
            balanceLabel.text = String.currency(value: status.realAmount)
            maturingLabel.text = String.currency(value: status.realMaturing)
            maxPrivacyLabel.text = String.currency(value: status.realMaxPrivacy)

            if status.realAmount == 0 {
                secondAvailableLabel.isHidden = true
            }
            else {
                secondAvailableLabel.isHidden = false
                secondAvailableLabel.text = AppModel.sharedManager().exchangeValue(status.realAmount)
                
                if secondAvailableLabel.text?.isEmpty == true {
                    secondAvailableLabel.isHidden = true
                }
            }

            secondAvailableLabel.isHidden = false
            secondAvailableLabel.text = AppModel.sharedManager().exchangeValue(status.realAmount)
            
            if status.realMaturing == 0 {
                secondMaturingLabel.isHidden = true
            }
            else {
                secondMaturingLabel.isHidden = false
                secondMaturingLabel.text = AppModel.sharedManager().exchangeValue(status.realMaturing)
                
                if secondMaturingLabel.text?.isEmpty == true {
                    secondMaturingLabel.isHidden = true
                }
            }
            
            if status.realMaxPrivacy == 0 {
                secondMaxPrivacyLabel.isHidden = true
            }
            else {
                secondMaxPrivacyLabel.isHidden = false
                secondMaxPrivacyLabel.text = AppModel.sharedManager().exchangeValue(status.realMaxPrivacy)
                
                if secondMaxPrivacyLabel.text?.isEmpty == true {
                    secondMaxPrivacyLabel.isHidden = true
                }
            }
        }
        else{
            balanceLabel.text = nil
            maturingLabel.text = nil
            secondAvailableLabel.isHidden = true
            secondMaturingLabel.isHidden = true
            secondMaxPrivacyLabel.isHidden = true
            moreDetailsButton.isHidden = true
        }
        
        expand(expand: options.expand, animation: false)
        didSelectState(animation: false)

        arrowIcon.alpha = Settings.sharedManager().isHideAmounts ? 0 : 1
        mainView.alpha =  Settings.sharedManager().isHideAmounts ? 0.7 : 1
        
        mainView.isUserInteractionEnabled =  Settings.sharedManager().isHideAmounts ? false : true
    }
}
