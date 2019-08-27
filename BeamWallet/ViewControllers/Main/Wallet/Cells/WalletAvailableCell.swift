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

    @IBOutlet weak private var availableView: UIView!
    @IBOutlet weak private var maturingView: UIView!

    @IBOutlet weak private var balanceLabel: UILabel!
    @IBOutlet weak private var balanceIcon: UIImageView!
    @IBOutlet weak private var currencyIcon: UIImageView!
    
    @IBOutlet weak private var maturingLabel: UILabel!
    @IBOutlet weak private var maturingCurrencyIcon: UIImageView!
    
    private var selectedState = StatusViewModel.SelectedState.available
    private var availableMaturing = false
    private var isExpand = true

    public static func hideHeight() -> CGFloat {
        return 78
    }
    
    public static func singleHeight() -> CGFloat {
        return 140.0
    }
    
    public static func maturingHeight() -> CGFloat {
        return 160.0
    }
        
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
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

        availableButton.setAttributedTitle(avaiableString, for: .normal)
        maturingButton.setAttributedTitle(maturingString, for: .normal)
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
        if selectedState == .available && sender == maturingButton {
            selectedState = .maturing
            delegate?.onDidChangeSelectedState(state: selectedState)
            didSelectState(animation: true)
        }
        else if selectedState == .maturing && sender == availableButton {
            selectedState = .available
            delegate?.onDidChangeSelectedState(state: selectedState)
            didSelectState(animation: true)
        }
    }
    
    @objc private func onSwipe(sender:UISwipeGestureRecognizer) {
        if isExpand {
            if sender.direction == .right && selectedState != .available {
                selectedState = .available
                delegate?.onDidChangeSelectedState(state: selectedState)
                didSelectState(animation: true)
            }
            else if sender.direction == .left && selectedState != .maturing {
                selectedState = .maturing
                delegate?.onDidChangeSelectedState(state: selectedState)
                didSelectState(animation: true)
            }
        }
    }
    
    private func expand(expand:Bool, animation:Bool) {        
        UIView.animate(withDuration: animation ? 0.3 : 0) {
            self.maturingView.isHidden = (expand ? false : true)
            self.availableView.isHidden = (expand ? false : true)
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
                self.availableView.alpha = 1
                
                self.availableButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.maturingButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }
            else{
                self.pageView.currentPage = 1
                
                self.maturingView.alpha = 1
                self.availableView.alpha = 0
                
                self.maturingButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.availableButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }
        }) { (_ ) in
            if self.selectedState == .available {
                self.availableButton.titleLabel?.font = BoldFont(size: size)
                self.maturingButton.titleLabel?.font = RegularFont(size: size)
            }
            else{
                self.maturingButton.titleLabel?.font = BoldFont(size: size)
                self.availableButton.titleLabel?.font = RegularFont(size: size)
            }
        }
    }
}

extension WalletAvailableCell: Configurable {
    
    func configure(with options: (expand: Bool, status:BMWalletStatus?, selectedState:StatusViewModel.SelectedState, avaiableMaturing:Bool)) {
        
        mainView.gestureRecognizers?.removeAll()

        selectedState = options.selectedState
        availableMaturing = options.avaiableMaturing
        isExpand = options.expand
        
        if availableMaturing {
            let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe))
            swipeLeft.direction = .left
            mainView.addGestureRecognizer(swipeLeft)
            
            let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe))
            swipeRight.direction = .right
            mainView.addGestureRecognizer(swipeRight)
            
            pageView.isHidden = false
            availableButton.isUserInteractionEnabled = true
            maturingButton.isHidden = false
        }
        else{
            pageView.isHidden = true
            availableButton.isUserInteractionEnabled = false
            maturingButton.isHidden = true
        }
        
        if let status = options.status {
            balanceLabel.text = String.currency(value: status.realAmount)
            maturingLabel.text = String.currency(value: status.realMaturing)
        }
        else{
            balanceLabel.text = nil
            maturingLabel.text = nil
        }
        
        expand(expand: options.expand, animation: false)
        didSelectState(animation: false)

        arrowIcon.alpha = Settings.sharedManager().isHideAmounts ? 0 : 1
        mainView.alpha =  Settings.sharedManager().isHideAmounts ? 0.7 : 1
        
        mainView.isUserInteractionEnabled =  Settings.sharedManager().isHideAmounts ? false : true
    }
}
