//
// BMGradientNavigationController.swift
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

class BMGradientNavigationController: UINavigationController {
    
    private var statusView:BMNetworkStatusView!
    private var statusViewY:CGFloat = 122
    private var titleLabel:UILabel!
    private let maxOffset:CGFloat = 65
    
    public var offset:CGFloat = 0 {
        didSet {
            if statusView != nil, titleLabel != nil {                
                let defaultX = (UIScreen.main.bounds.size.width - titleLabel.frame.size.width)/2
                
                let maxX = (UIScreen.main.bounds.size.width - titleLabel.frame.size.width - 15)
                
                let progress = (offset/maxOffset)

                titleLabel.frame = CGRect(x: defaultX + (progress * maxX), y: 55, width: titleLabel.frame.size.width, height: 50)
                titleLabel.alpha = 1 - progress

                statusView.y = statusViewY - offset
                statusView.x = (offset > 35) ? 35 : offset
            }
        }
    }
    
    init() {
        super.init(navigationBarClass: BMGradientNavigationBar.self, toolbarClass: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override init(rootViewController: UIViewController) {
        super.init(navigationBarClass: BMGradientNavigationBar.self, toolbarClass: nil)
        
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        self.navigationBar.backgroundColor = .clear
        self.navigationBar.tintColor = UIColor.white
        
        self.viewControllers = [rootViewController]
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel = UILabel()
        navigationBar.addSubview(titleLabel)

 
    }
    
    override var title: String? {
        willSet {
            if let titleString = newValue {
                let attributedString = NSMutableAttributedString(string: titleString)
                attributedString.addAttribute(NSAttributedString.Key.kern, value: CGFloat(2), range: NSRange(location: 0, length: titleString.lengthOfBytes(using: .utf8) ))
                
                let w = UIScreen.main.bounds.size.width
                
                titleLabel.frame = CGRect(x: 0, y: 55, width: 0, height: 50)
                titleLabel.font = ProMediumFont(size: 20)
                titleLabel.numberOfLines = 1
                titleLabel.attributedText = attributedString
                titleLabel.textColor = UIColor.white
                titleLabel.textAlignment = .center
                titleLabel.sizeToFit()
                
                if titleLabel.frame.size.width > (UIScreen.main.bounds.size.width - 100)
                {
                    let labelMaxW = (UIScreen.main.bounds.size.width - 100)
                    titleLabel.frame = CGRect(x: (w - labelMaxW)/2, y: 55, width: labelMaxW, height: 50)
                }
                else{
                    titleLabel.frame = CGRect(x: (w - titleLabel.frame.size.width)/2, y: 55, width: titleLabel.frame.size.width, height: 50)
                }
                
                titleLabel.adjustsFontSizeToFitWidth = true
                titleLabel.minimumScaleFactor = 0.7
            }
        }
    }
}
