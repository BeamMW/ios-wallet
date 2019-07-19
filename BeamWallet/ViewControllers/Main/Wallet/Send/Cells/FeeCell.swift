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
    @IBOutlet weak private var titleLabel: UILabel!

    private let stepValue:Float = 10
    
    weak var delegate: BMCellProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        feeSlider.maximumTrackTintColor = UIColor.main.marineThree
        feeSlider.isContinuous = true
        feeSlider.setThumbImage(SliderDot(), for: .normal)
        feeSlider.setThumbImage(SliderDot(), for: .highlighted)
        feeSlider.maximumTrackTintColor = UIColor.main.marineThree
        feeSlider.minimumValue = Float(AppModel.sharedManager().getMinFeeInGroth())

        minLabel.text = String(Int(feeSlider.minimumValue)) + Localizable.shared.strings.groth
       
        titleLabel.text = Localizable.shared.strings.transaction_fee.uppercased()

        selectionStyle = .none
        
        contentView.backgroundColor = UIColor.main.marineThree
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        let point = setUISliderThumbValueWithLabel(slider: feeSlider)
        valueLabel.frame = CGRect(x: point.x, y: 35, width: valueLabel.frame.size.width, height: valueLabel.frame.size.height)
    }
    
    @IBAction private func showPicker(_ sender: UIButton) {
        let modalViewController = InputFeePopover()
        modalViewController.mainFee = (valueLabel.text?.replacingOccurrences(of: Localizable.shared.strings.groth, with: "")) ?? ""
        modalViewController.modalPresentationStyle = .overFullScreen
        modalViewController.modalTransitionStyle = .crossDissolve
        modalViewController.completion = {
            (obj : String) -> Void in
            
            let nFee = Double(obj) ?? 0
            
            if nFee > Double(self.feeSlider.maximumValue) {
                self.feeSlider.maximumValue = Float(nFee)
                self.maxLabel.text = obj + Localizable.shared.strings.groth
            }
            
            self.configure(with: nFee)
            self.delegate?.onDidChangeFee?(value: nFee)
        }
        if let vc = UIApplication.getTopMostViewController() {
            vc.present(modalViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction private func sliderValueChanged(_ sender: UISlider) {
        let roundedStepValue = round(sender.value / stepValue) * stepValue
        sender.value = roundedStepValue

        valueLabel.text = String(Int(roundedStepValue)) + Localizable.shared.strings.groth
        valueLabel.sizeToFit()
        
        let point = setUISliderThumbValueWithLabel(slider: sender)
        valueLabel.frame = CGRect(x: point.x, y: 35, width: valueLabel.frame.size.width, height: valueLabel.frame.size.height)
        
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
        if fee > Double(feeSlider.maximumValue) {
            feeSlider.maximumValue = Float(fee)
            maxLabel.text = String(Int(fee)) + Localizable.shared.strings.groth
        }
        
        feeSlider.value = Float(fee)
        
        valueLabel.text = String(Int(fee)) + Localizable.shared.strings.groth
        valueLabel.sizeToFit()
        
        let point = setUISliderThumbValueWithLabel(slider: feeSlider)
        valueLabel.frame = CGRect(x: point.x, y: 90, width: valueLabel.frame.size.width, height: valueLabel.frame.size.height)    
    }
}
