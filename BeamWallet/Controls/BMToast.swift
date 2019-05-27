//
//  BMToast.swift
//  BeamWallet
//
//  Created by Denis on 5/24/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class BMToast: UIView {
    private static let seconds = 1.5
    
    private static var toast: BMToast!
    private static var timer:Timer!
    
    init(text:String) {
        let offset:CGFloat = (Device.screenType == .iPhone_XR || Device.screenType == .iPhone_XSMax || Device.screenType == .iPhones_X_XS) ? 40 : 15

        super.init(frame: CGRect(x: (UIScreen.main.bounds.size.width - 280) / 2, y: UIScreen.main.bounds.size.height - 44 - offset, width: 280, height: 44))
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        self.layer.cornerRadius = self.bounds.size.height / 2
        
        let label = UILabel(frame: CGRect(x: 20, y: 5, width: 240, height: 34))
        label.font = RegularFont(size: 16)
        label.textColor = UIColor.white
        label.text = text
        label.textAlignment = .center
        addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    public static func show(text:String) {
        
        if timer != nil {
            timer.invalidate()
            timer = nil
        }

        timer = Timer.scheduledTimer(timeInterval: TimeInterval(seconds), target: self, selector: #selector(BMToast.dismiss), userInfo: nil, repeats: false)

        
        if toast != nil {
            toast.removeFromSuperview()
            toast = nil
        }
        
        let app = UIApplication.shared.delegate as! AppDelegate
        
        toast = BMToast(text: text)
    
        app.window?.addSubview(toast)
    
        toast.popIn()
    }
    
    @objc public static func dismiss() {
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
