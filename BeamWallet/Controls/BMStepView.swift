//
//  BMStepView.swift
//  BeamWallet
//
// 3/1/19.
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

class BMStepView: UIView {

    var totalStep = 6
    var currentStep = 0 {
        didSet{
            layout()
        }
    }
    var finishedStepColor = UIColor.main.red

    private var views = [UIView]()
    
    private func layout() {
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let separate:CGFloat = 5.0
        let stepWidth = round((self.frame.size.width - separate * CGFloat(totalStep)) / CGFloat(totalStep));
        
        if views.count > 0
        {
            for view in views {
                view.frame =  CGRect(x: CGFloat(view.tag) * (stepWidth + separate), y: 0, width: stepWidth, height: self.frame.size.height)
                if view.tag < currentStep {
                    UIView.animate(withDuration: 0.2) {
                        view.layer.borderColor = UIColor.clear.cgColor
                        view.backgroundColor = self.finishedStepColor;
                    }
                }
                else{
                    UIView.animate(withDuration: 0.2) {
                        view.layer.borderColor = UIColor.main.darkSlateBlue.cgColor
                        view.backgroundColor = UIColor.clear;
                    }
                }
            }
        }
        else{
            for i in 0 ... totalStep - 1 {
                let view = UIView(frame: CGRect(x: CGFloat(i) * (stepWidth + separate), y: 0, width: stepWidth, height: self.frame.size.height))
                view.layer.cornerRadius = view.frame.size.height/2
                view.layer.borderColor = UIColor.main.darkSlateBlue.cgColor
                view.backgroundColor = UIColor.clear;
                view.layer.borderWidth = 1;
                view.tag = i
                views.append(view)
                self.addSubview(view)
            }
        }
    }
}
