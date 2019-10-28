//
//  BMInputViewController.swift
//  BeamWallet
//
//  Created by Denis on 10/21/19.
//  Copyright © 2019 Denis. All rights reserved.
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
