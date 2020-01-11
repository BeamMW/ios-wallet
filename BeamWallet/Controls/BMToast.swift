//
// BMToast.swift
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

class BMToast: UIView {
    private static let seconds = 2.0
    
    private static var toast: BMToast!
    private static var timer:Timer!
    private static var onDismissed : (() -> Void)?

    init(text:String, shadow:Bool = true, block:(() -> Void)? = nil) {
        let offset:CGFloat = (Device.screenType == .iPhone_XR || Device.screenType == .iPhone_XSMax || Device.screenType == .iPhones_X_XS) ? 40 : 15

        let w = UIScreen.main.bounds.size.width - 40
        
        var textSize = text.boundingRect(with: CGSize(width: w - 30, height: 9999), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: RegularFont(size: 14)], context: nil)
        
        if(textSize.height<34) {
            textSize.size.height = 34
        }
        
        super.init(frame: CGRect(x: 20, y: UIScreen.main.bounds.size.height - offset - textSize.height, width: w, height: textSize.height + 10))
        
        backgroundColor = UIColor.white
        
        layer.cornerRadius = 8
        layer.masksToBounds = false
   
        if shadow {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 1)
            layer.shadowOpacity = 0.45
            layer.shadowPath = UIBezierPath(rect: bounds).cgPath
            layer.shadowRadius = 1.0
        }
        
        
        
        let label = UILabel(frame: CGRect(x: 20, y: 5, width: frame.size.width - 30, height: textSize.height))
        label.font = RegularFont(size: 14)
        label.textColor = UIColor.main.marineOriginal
        label.text = text
        label.numberOfLines = 0
        label.textAlignment = .left
        addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    public static func show(text:String, shadow:Bool = true, duration:Double? = nil, block:(() -> Void)? = nil) {
        
        BMToast.onDismissed = block
        
        if timer != nil {
            timer.invalidate()
            timer = nil
        }

        timer = Timer.scheduledTimer(timeInterval: TimeInterval(duration == nil ? seconds : duration!), target: self, selector: #selector(BMToast.dismiss), userInfo: nil, repeats: false)

        
        if toast != nil {
            toast.removeFromSuperview()
            toast = nil
        }
        
        let app = UIApplication.shared.delegate as! AppDelegate
        
        toast = BMToast(text: text, shadow: shadow, block: block)
    
        app.window?.addSubview(toast)
    
        toast.popIn()
    }
    
    @objc private func dismissTimer() {
        BMToast.dismiss()
    }
    
    @objc public static func dismiss() {
        BMToast.onDismissed?()

        if BMToast.timer != nil {
            BMToast.timer.invalidate()
            BMToast.timer = nil
        }
        
        if BMToast.toast != nil {
            BMToast.toast.popOut {
                BMToast.toast.removeFromSuperview()
                BMToast.toast = nil
            }
        }
    }
}
