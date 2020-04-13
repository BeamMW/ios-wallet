//
// InputFeePopover.swift
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

class InputFeePopover: BaseViewController {

    public var completion : ((String) -> Void)?
    public var mainFee:String!

    @IBOutlet weak private var feeField: BMField!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var grothTitleLabelY: NSLayoutConstraint!
    @IBOutlet weak private var mainView: UIView!
    @IBOutlet private weak var secondAvailableLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        secondAvailableLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        secondAvailableLabel.font = RegularFont(size: 14)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if let image = appDelegate.window?.snapshot() {
            let blured = image.blurredImage(withRadius: 10, iterations: 5, tintColor: UIColor.main.blurBackground)
            let imageView = UIImageView(frame: UIScreen.main.bounds)
            imageView.image = blured
            view.insertSubview(imageView, at: 0)
        }
        
        mainView.addShadow(offset: CGSize(width: 0, height: -5), color: UIColor.black, opacity: 0.3, radius: 5)
        
        titleLabel.text = Localizable.shared.strings.transaction_fee.uppercased()
        if Settings.sharedManager().isDarkMode {
            titleLabel.textColor = UIColor.main.steel
            mainView.backgroundColor = UIColor.main.twilightBlue2
        }
        
        feeField.text = mainFee
        secondAvailableLabel.text = AppModel.sharedManager().exchangeValueFee(Double(mainFee) ?? 0)
        
        addSwipeToDismiss()
        
        hideKeyboardWhenTappedAround()
    }
    
    @IBAction func onSave(sender :UIButton) {
        feeField.resignFirstResponder()
        
        if mainFee.isEmpty {
            mainFee = Localizable.shared.strings.zero
        }
        
        let v = Int32(mainFee) ?? 0
        
        if v < AppModel.sharedManager().getMinFeeInGroth() {
            grothTitleLabelY.constant = 5
            
            feeField.error = Localizable.shared.strings.min_fee_error.replacingOccurrences(of: ("(value)"), with: String(AppModel.sharedManager().getMinFeeInGroth()))
            feeField.status = .error
        }
        else{
            completion?(mainFee)
            
            dismiss(animated: true, completion:nil)
        }
    }
    
    @IBAction func onClose(sender :UIButton) {
        dismiss(animated: true, completion:nil)
    }
}

extension InputFeePopover : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        grothTitleLabelY.constant = 15

        let mainCount = 15
        
        let textFieldText: NSString = (textField.text ?? "") as NSString
        
        let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string).replacingOccurrences(of: ",", with: ".")
        
        if Double(txtAfterUpdate) == nil && !txtAfterUpdate.isEmpty {
            return false
        }
        
        if txtAfterUpdate.lengthOfBytes(using: .utf8) > mainCount {
            return false
        }
        
        if (!txtAfterUpdate.isDecimial()) {
            return false
        }
        
        if txtAfterUpdate.contains(".") {
            return false
        }
        
        let fee = Double(txtAfterUpdate.replacingOccurrences(of: ",", with: ".") )
        let amount:Double = Double(0)
        
        if AppModel.sharedManager().canReceive(amount, fee: fee ?? 0) != nil {
            return false
        }
        
        textField.text = txtAfterUpdate
        
        mainFee = txtAfterUpdate
        secondAvailableLabel.text = AppModel.sharedManager().exchangeValueFee(Double(mainFee) ?? 0)

        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text {
            if let v = Double(text) {
                if v == 0 {
                    textField.text = Localizable.shared.strings.zero
                }
                else if textField == feeField {
                    textField.text = String(Int(v))
                }
            }
            else{
                textField.text = Localizable.shared.strings.zero
            }
            
            mainFee = textField.text!
        }
    }
}
