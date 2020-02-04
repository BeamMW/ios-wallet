//
// BMInputViewController.swift
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

class BMInputViewController: BaseViewController {

    @IBOutlet internal var inputField: BMField!
    @IBOutlet internal var titleLabel: UILabel!
    @IBOutlet internal var nextButton: BMButton!
    @IBOutlet internal var errorLabel: UILabel!
    @IBOutlet internal var stackView: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboardWhenTappedAround()
        
        errorLabel.textColor = UIColor.main.red
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: false)
        
        nextButton.addTarget(self, action: #selector(onNext), for: .touchUpInside)
    }
    
    @objc internal func onNext() {
        
    }
}
