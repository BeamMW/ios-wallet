//
//  BMStepView.swift
//  BeamWallet
//
//  Created by Denis on 3/1/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class BMStepView: UIView {

    var totalStep = 6
    var currentStep = 0
    var finishedStepColor = UIColor.main.red
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let separate:CGFloat = 5.0
        let stepWidth = round((self.frame.size.width - separate * 1) / CGFloat(totalStep));
        
        for i in 0 ... totalStep - 1 {
            let view = UIView(frame: CGRect(x: CGFloat(i) * stepWidth + separate, y: 0, width: stepWidth-separate, height: self.frame.size.height))
            view.backgroundColor = UIColor.clear;
            view.layer.cornerRadius = view.frame.size.height/2
            view.layer.borderColor = UIColor.main.darkSlateBlue.cgColor
            view.layer.borderWidth = 1;
            self.addSubview(view)
        }
    }
   
}
