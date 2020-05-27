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
    func onDidSelectUnlink()
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
    @IBOutlet weak private var unkinkTopButtonButton: UIButton!

    @IBOutlet weak private var availableView: UIView!
    @IBOutlet weak private var maturingView: UIView!
    @IBOutlet weak private var unlinkView: UIView!

    @IBOutlet weak private var balanceLabel: UILabel!
    @IBOutlet weak private var balanceIcon: UIImageView!
    @IBOutlet weak private var currencyIcon: UIImageView!
    
    @IBOutlet weak private var maturingLabel: UILabel!
    @IBOutlet weak private var maturingCurrencyIcon: UIImageView!
    
    @IBOutlet weak private var unlinkLabel: UILabel!
    @IBOutlet weak private var unlinkCurrencyIcon: UIImageView!
    
    @IBOutlet weak private var secondAvailableLabel: UILabel!
    @IBOutlet weak private var secondMaturingLabel: UILabel!
    @IBOutlet weak private var secondUnlinkLabel: UILabel!

    @IBOutlet weak private var unlinkButton: UIButton!

    private var selectedState = StatusViewModel.SelectedState.available
    private var availableMaturing = false
    private var availableUnlink = false

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
        return 166.0
    }
        
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        secondMaturingLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        secondAvailableLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        secondUnlinkLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey

        secondMaturingLabel.font = RegularFont(size: 14)
        secondAvailableLabel.font = RegularFont(size: 14)
        secondUnlinkLabel.font = RegularFont(size: 14)

        unlinkCurrencyIcon.image = IconSymbolBeam()?.withRenderingMode(.alwaysTemplate)
        unlinkCurrencyIcon.tintColor = UIColor.white
        
        currencyIcon.image = IconSymbolBeam()?.withRenderingMode(.alwaysTemplate)
        currencyIcon.tintColor = UIColor.white
        
        maturingCurrencyIcon.image = IconSymbolBeam()?.withRenderingMode(.alwaysTemplate)
        maturingCurrencyIcon.tintColor = UIColor.white
        
        mainView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        
        mainButton.setBackgroundImage(UIImage.fromColor(color: UIColor.black.withAlphaComponent(0.3)), for: .highlighted)
        
        let avaiableString = NSMutableAttributedString(string: Localizable.shared.strings.available.uppercased())
        avaiableString.addAttribute(NSAttributedString.Key.kern, value: CGFloat(1.5), range: NSRange(location: 0, length: avaiableString.string.count))
        avaiableString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.blueyGrey, range: NSRange(location: 0, length: avaiableString.string.count))

        let maturingString = NSMutableAttributedString(string: Localizable.shared.strings.maturing.uppercased())
        maturingString.addAttribute(NSAttributedString.Key.kern, value: CGFloat(1.5), range: NSRange(location: 0, length: maturingString.string.count))
        maturingString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.blueyGrey, range: NSRange(location: 0, length: maturingString.string.count))

        let unlinkString = NSMutableAttributedString(string: Localizable.shared.strings.unlinked.uppercased())
        unlinkString.addAttribute(NSAttributedString.Key.kern, value: CGFloat(1.5), range: NSRange(location: 0, length: unlinkString.string.count))
        unlinkString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.blueyGrey, range: NSRange(location: 0, length: unlinkString.string.count))
        
        availableButton.setAttributedTitle(avaiableString, for: .normal)
        maturingButton.setAttributedTitle(maturingString, for: .normal)
        unkinkTopButtonButton.setAttributedTitle(unlinkString, for: .normal)

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
        else if selectedState != .unlink && sender == unkinkTopButtonButton {
            selectedState = .unlink
            delegate?.onDidChangeSelectedState(state: selectedState)
            didSelectState(animation: true)
        }
    }
    
    @IBAction func onUnlink(sender :UIButton) {
        self.delegate?.onDidSelectUnlink()
    }
    
    @objc private func onSwipe(sender:UISwipeGestureRecognizer) {
        if isExpand {
            if sender.direction == .right {
                if selectedState == .unlink {
                    selectedState = .available
                    delegate?.onDidChangeSelectedState(state: selectedState)
                    didSelectState(animation: true)
                }
                else if selectedState == .maturing {
                    if availableUnlink {
                        selectedState = .unlink
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
                    if availableUnlink {
                        selectedState = .unlink
                        delegate?.onDidChangeSelectedState(state: selectedState)
                        didSelectState(animation: true)
                    }
                    else if availableMaturing {
                        selectedState = .maturing
                        delegate?.onDidChangeSelectedState(state: selectedState)
                        didSelectState(animation: true)
                    }
                }
                else if selectedState == .unlink {
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
            self.unlinkView.isHidden = (expand ? false : true)
            self.pageView.alpha = (expand ? 1 : 0)
            self.buttonsStackView.isUserInteractionEnabled = (expand ? true : false)
            self.arrowIcon.transform = CGAffineTransform(rotationAngle: expand ? CGFloat(0 * Double.pi/180) : CGFloat(-90 * Double.pi/180))
        }
    }
    
    private func didSelectState(animation:Bool) {
        let size = self.availableButton.titleLabel?.font.pointSize ?? 14

        UIView.animate(withDuration: animation ? 0.3 : 0, animations: {
            if self.selectedState == .available {
                self.pageView.currentPage = 0
                
                self.maturingView.alpha = 0
                self.unlinkView.alpha = 0
                self.availableView.alpha = 1
                
                self.availableButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.maturingButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                self.unkinkTopButtonButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }
            else if self.selectedState == .maturing {
                self.pageView.currentPage = (self.availableUnlink) ? 2 : 1
                
                self.maturingView.alpha = 1
                self.availableView.alpha = 0
                self.unlinkView.alpha = 0

                self.maturingButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.availableButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                self.unkinkTopButtonButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }
            else if self.selectedState == .unlink {
                self.pageView.currentPage = 1
                
                self.maturingView.alpha = 0
                self.availableView.alpha = 0
                self.unlinkView.alpha = 1
                
                self.unkinkTopButtonButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.availableButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                self.maturingButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }
        }) { (_ ) in
            if self.selectedState == .available {
                self.availableButton.titleLabel?.font = BoldFont(size: size)
                self.maturingButton.titleLabel?.font = RegularFont(size: size)
                self.unkinkTopButtonButton.titleLabel?.font = RegularFont(size: size)
            }
            else if self.selectedState == .unlink {
                self.unkinkTopButtonButton.titleLabel?.font = BoldFont(size: size)
                self.availableButton.titleLabel?.font = RegularFont(size: size)
                self.maturingButton.titleLabel?.font = RegularFont(size: size)
            }
            else{
                self.maturingButton.titleLabel?.font = BoldFont(size: size)
                self.availableButton.titleLabel?.font = RegularFont(size: size)
                self.unkinkTopButtonButton.titleLabel?.font = RegularFont(size: size)
            }
        }
    }
}

extension WalletAvailableCell: Configurable {
    
    func configure(with options: (expand: Bool, status:BMWalletStatus?, selectedState:StatusViewModel.SelectedState, avaiableMaturing:Bool, avaiableUnlink:Bool)) {
        
        mainView.gestureRecognizers?.removeAll()

        selectedState = options.selectedState
        availableMaturing = options.avaiableMaturing
        availableUnlink = options.avaiableUnlink

        isExpand = options.expand
        
        if availableMaturing || availableUnlink {
            let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe))
            swipeLeft.direction = .left
            mainView.addGestureRecognizer(swipeLeft)
            
            let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe))
            swipeRight.direction = .right
            mainView.addGestureRecognizer(swipeRight)
            
            pageView.isHidden = false
            pageView.numberOfPages = (availableUnlink && availableMaturing) ? 3 : 2

            maturingButton.isHidden = !availableMaturing
            unkinkTopButtonButton.isHidden = !availableUnlink
        }
        else{
            pageView.isHidden = true
            maturingButton.isHidden = true
            unkinkTopButtonButton.isHidden = true
        }
        
        if let status = options.status {
            balanceLabel.text = String.currency(value: status.realAmount)
            maturingLabel.text = String.currency(value: status.realMaturing)
            unlinkLabel.text = String.currency(value: status.realShilded)

            if status.realAmount == 0 {
                secondAvailableLabel.isHidden = true
                unlinkButton.isHidden = true
            }
            else {
                secondAvailableLabel.isHidden = false
                unlinkButton.isHidden = false
                secondAvailableLabel.text = AppModel.sharedManager().exchangeValue(status.realAmount)
                
                if secondAvailableLabel.text?.isEmpty == true {
                    secondAvailableLabel.isHidden = true
                }
            }

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
            
            if status.realShilded == 0 {
                secondUnlinkLabel.isHidden = true
            }
            else {
                secondUnlinkLabel.isHidden = false
                secondUnlinkLabel.text = AppModel.sharedManager().exchangeValue(status.realShilded)
                
                if secondUnlinkLabel.text?.isEmpty == true {
                    secondUnlinkLabel.isHidden = true
                }
            }
        }
        else{
            balanceLabel.text = nil
            maturingLabel.text = nil
            secondAvailableLabel.isHidden = true
            secondMaturingLabel.isHidden = true
            secondUnlinkLabel.isHidden = true
            unlinkButton.isHidden = true
        }
        
        expand(expand: options.expand, animation: false)
        didSelectState(animation: false)

        arrowIcon.alpha = Settings.sharedManager().isHideAmounts ? 0 : 1
        mainView.alpha =  Settings.sharedManager().isHideAmounts ? 0.7 : 1
        
        mainView.isUserInteractionEnabled =  Settings.sharedManager().isHideAmounts ? false : true
    }
}
