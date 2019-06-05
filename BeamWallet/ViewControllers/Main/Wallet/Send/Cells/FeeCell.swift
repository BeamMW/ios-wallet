//
// FeeCell.swift
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

class FeeCell: BaseCell {

    @IBOutlet weak private var valueLabel: UILabel!
    @IBOutlet weak private var maxLabel: UILabel!
    @IBOutlet weak private var feeSlider: BMSlider!
    @IBOutlet weak private var mainView: UIView!

    private let stepValue:Float = 10
    
    weak var delegate: BMCellProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(showPicker))
        longPress.minimumPressDuration = 1
        
        //valueLabel.isUserInteractionEnabled = true
        mainView.addGestureRecognizer(longPress)
        
        
        feeSlider.maximumTrackTintColor = UIColor.main.marineTwo.withAlphaComponent(0.8)
        feeSlider.isContinuous = true
        feeSlider.setThumbImage(SliderDot(), for: .normal)
        feeSlider.setThumbImage(SliderDot(), for: .highlighted)
        feeSlider.maximumTrackTintColor = Settings.sharedManager().target == Testnet ? UIColor.main.marineTwo.withAlphaComponent(0.8) : UIColor.main.darkSlateBlue.withAlphaComponent(0.8)

        selectionStyle = .none
        
        contentView.backgroundColor = UIColor.main.marineTwo.withAlphaComponent(0.35)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        let point = setUISliderThumbValueWithLabel(slider: feeSlider)
        valueLabel.frame = CGRect(x: point.x, y: point.y, width: valueLabel.frame.size.width, height: valueLabel.frame.size.height)
    }
    
    @objc private func showPicker(sender:UILongPressGestureRecognizer) {
        if sender.state == .began {
            let modalViewController = InputFeePopover()
            modalViewController.mainFee = (valueLabel.text?.replacingOccurrences(of: LocalizableStrings.groth, with: "")) ?? ""
            modalViewController.modalPresentationStyle = .overFullScreen
            modalViewController.modalTransitionStyle = .crossDissolve
            modalViewController.completion = {
                (obj : String) -> Void in
                
                let nFee = Double(obj) ?? 0
                
                if nFee > Double(self.feeSlider.maximumValue) {
                    self.feeSlider.maximumValue = Float(nFee)
                    self.maxLabel.text = obj + LocalizableStrings.groth
                }
                
                self.configure(with: nFee)
                self.delegate?.onDidChangeFee?(value: nFee)
            }
            if let vc = UIApplication.getTopMostViewController() {
                vc.present(modalViewController, animated: true, completion: nil)
            }
        }
 
    }
    
    @IBAction private func sliderValueChanged(_ sender: UISlider) {
        let roundedStepValue = round(sender.value / stepValue) * stepValue
        sender.value = roundedStepValue

        valueLabel.text = String(Int(roundedStepValue)) + LocalizableStrings.groth
        valueLabel.sizeToFit()
        
        let point = setUISliderThumbValueWithLabel(slider: sender)
        valueLabel.frame = CGRect(x: point.x, y: point.y, width: valueLabel.frame.size.width, height: valueLabel.frame.size.height)
        
        delegate?.onDidChangeFee?(value: Double(roundedStepValue))
    }
    
    private func setUISliderThumbValueWithLabel(slider: UISlider) -> CGPoint {
        let slidertTrack = slider.trackRect(forBounds: slider.bounds)
        let sliderFrm = slider.thumbRect(forBounds: slider.bounds, trackRect: slidertTrack, value: slider.value)
        
        var x = sliderFrm.origin.x

        if ((x + valueLabel.frame.size.width) > (UIScreen.main.bounds.size.width - 15)) {
            x = UIScreen.main.bounds.size.width - 15 - valueLabel.frame.size.width
        }
        else if (x < 15) {
            x = 15
        }
        
        let point = CGPoint(x: x, y: slider.frame.origin.y + slider.frame.size.height + 5)
        
        return point
    }
}

extension FeeCell: Configurable {
    
    func configure(with fee:Double) {
        feeSlider.value = Float(fee)
        
        valueLabel.text = String(Int(fee)) + LocalizableStrings.groth
        valueLabel.sizeToFit()
        
        let point = setUISliderThumbValueWithLabel(slider: feeSlider)
        valueLabel.frame = CGRect(x: point.x, y: point.y, width: valueLabel.frame.size.width, height: valueLabel.frame.size.height)
    }
}
