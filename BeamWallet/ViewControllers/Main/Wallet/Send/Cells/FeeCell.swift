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
    @IBOutlet weak private var minLabel: UILabel!
    @IBOutlet weak private var maxLabel: UILabel!
    @IBOutlet weak private var feeSlider: BMSlider!
    @IBOutlet weak private var mainView: UIView!

    @IBOutlet weak private var minSecondLabel: UILabel!
    @IBOutlet weak private var maxSecondLabel: UILabel!

    private var valueY:CGFloat = 0
    private let stepValue:Float = 10
    private var type: BMTransactionType = BMTransactionType(BMTransactionTypeSimple)

    weak var delegate: BMCellProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        maxSecondLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        maxSecondLabel.font = RegularFont(size: 14)
        
        minSecondLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        minSecondLabel.font = RegularFont(size: 14)
        
        feeSlider.maximumTrackTintColor = UIColor.main.marineThree
        feeSlider.isContinuous = true
        feeSlider.setThumbImage(SliderDot(), for: .normal)
        feeSlider.setThumbImage(SliderDot(), for: .highlighted)
        feeSlider.maximumTrackTintColor = UIColor.main.marineThree
        feeSlider.minimumValue = Float(AppModel.sharedManager().getMinFeeInGroth())
        feeSlider.addTarget(self, action: #selector(onSliderValChanged(sender:event:)), for: .valueChanged)

        minLabel.text = String(Int(feeSlider.minimumValue)) + Localizable.shared.strings.groth
        minSecondLabel.text = AppModel.sharedManager().exchangeValueFee(Double(feeSlider.minimumValue))

        if Settings.sharedManager().isDarkMode {
            feeSlider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.02)
        }

        selectionStyle = .none
        
        contentView.backgroundColor = UIColor.main.marineThree
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        let point = setUISliderThumbValueWithLabel(slider: feeSlider)
        valueLabel.frame = CGRect(x: point.x, y: valueY, width: valueLabel.frame.size.width, height: valueLabel.frame.size.height)
    }
    
    @IBAction private func showPicker(_ sender: UIButton) {
        let modalViewController = InputFeePopover()
        modalViewController.mainFee = (valueLabel.text?.replacingOccurrences(of: Localizable.shared.strings.groth, with: "")) ?? ""
        modalViewController.minFee = UInt64(self.feeSlider.minimumValue)
        modalViewController.modalPresentationStyle = .overFullScreen
        modalViewController.modalTransitionStyle = .crossDissolve
        modalViewController.type = self.type
        modalViewController.completion = {
            (obj : String) -> Void in
            
            let nFee = Double(obj) ?? 0
            
            if nFee > Double(self.feeSlider.maximumValue) {
                self.feeSlider.maximumValue = Float(nFee)
                self.maxLabel.text = obj + Localizable.shared.strings.groth
                self.maxSecondLabel.text = AppModel.sharedManager().exchangeValueFee(nFee)
            }
            
            self.configure(with: nFee)
            self.delegate?.onDidChangeFee?(value: nFee)
        }
        if let vc = UIApplication.getTopMostViewController() {
            vc.present(modalViewController, animated: true, completion: nil)
        }
    }
    
    @objc func onSliderValChanged(sender: UISlider, event: UIEvent) {
        let roundedStepValue = round(sender.value / stepValue) * stepValue
        sender.value = roundedStepValue

        valueLabel.text = String(Int(roundedStepValue)) + Localizable.shared.strings.groth
        valueLabel.sizeToFit()
        
        let point = setUISliderThumbValueWithLabel(slider: sender)
        valueLabel.frame = CGRect(x: point.x, y: valueY, width: valueLabel.frame.size.width, height: valueLabel.frame.size.height)
        
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .ended:
                delegate?.onDidChangeFee?(value: Double(roundedStepValue))
            default:
                break
            }
        }
    }
    
    private func setUISliderThumbValueWithLabel(slider: UISlider) -> CGPoint {
        let slidertTrack = slider.trackRect(forBounds: slider.bounds)
        let sliderFrm = slider.thumbRect(forBounds: slider.bounds, trackRect: slidertTrack, value: slider.value)
        
        var x = sliderFrm.origin.x

        if ((x + valueLabel.frame.size.width) > (UIScreen.main.bounds.size.width - 70)) {
            x = UIScreen.main.bounds.size.width - 70 - valueLabel.frame.size.width
        }
        else if (x < 15) {
            x = 15
        }
        
        let point = CGPoint(x: x, y: slider.frame.origin.y + slider.frame.size.height + 5)
        
        return point
    }
}

extension FeeCell: Configurable {
    
    func setMinFee(minFee: UInt64) {
        if(minFee > 300) {
            feeSlider.minimumValue = Float(minFee)
            if feeSlider.maximumValue <= Float(minFee) {
                feeSlider.maximumValue = Float(minFee+minFee)
            }
        }
        else {
            feeSlider.maximumValue = Float(2000)
            feeSlider.minimumValue = Float(AppModel.sharedManager().getMinFeeInGroth())
        }
        
        minLabel.text = String(Int(feeSlider.minimumValue)) + Localizable.shared.strings.groth
        maxLabel.text = String(Int(feeSlider.maximumValue)) + Localizable.shared.strings.groth
        
    }
        
    func configure(with fee:Double) {
        if fee > Double(feeSlider.maximumValue) {
            feeSlider.maximumValue = Float(fee)
            maxLabel.text = String(Int(fee)) + Localizable.shared.strings.groth
        }
        maxSecondLabel.text = AppModel.sharedManager().exchangeValueFee(Double(feeSlider.maximumValue))

        feeSlider.value = Float(fee)
        
        valueLabel.text = String(Int(fee)) + Localizable.shared.strings.groth
        valueLabel.sizeToFit()
        
        let point = setUISliderThumbValueWithLabel(slider: feeSlider)
        valueLabel.frame = CGRect(x: point.x, y: 90, width: valueLabel.frame.size.width, height: valueLabel.frame.size.height)    
    }
}
