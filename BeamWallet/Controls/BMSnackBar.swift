//
// BMSnackBar.swift
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

class BMSnackBar: UIView, CountdownViewDelegate {
    
    enum SnackType {
        case transaction
        case address
        case contact
    }

    struct SnackData {
        var type:SnackType!
        var id:String!
        
        init(type:SnackType!, id:String!) {
            self.type = type
            self.id = id
        }
    }
    
    private var data:SnackData!
    private var done : ((_ clickUndo : SnackData?) -> Void)!
    private var ended : ((_ clickUndo : SnackData?) -> Void)!
    private var timer:CountdownView?
    
    fileprivate init(data:SnackData!, done: @escaping (SnackData?) -> Void, ended: @escaping (SnackData?) -> Void) {
        let offset:CGFloat = (Device.screenType == .iPhone_XR || Device.screenType == .iPhone_XSMax || Device.screenType == .iPhones_X_XS) ? 40 : 15

        super.init(frame: CGRect(x: 20, y: UIScreen.main.bounds.size.height - 48 - offset, width: UIScreen.main.bounds.size.width - 40, height: 48))

        self.data = data
        self.done = done
        self.ended = ended

        backgroundColor = UIColor.white
        
        layer.cornerRadius = 8
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.45
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shadowRadius = 1.0
        
        let label = UILabel(frame: CGRect(x: 60, y: 0, width: 150, height: 48))
        label.font = RegularFont(size: 14)
        label.textColor = UIColor.main.marineOriginal
        

        if data.type == BMSnackBar.SnackType.contact {
            self.data.type = .address
            label.text = LocalizableStrings.contact_deleted
        }
        else if data.type == BMSnackBar.SnackType.address {
            label.text = LocalizableStrings.address_deleted
        }
        else{
            label.text = LocalizableStrings.beams_send
        }
      
        addSubview(label)
        
        let button = UIButton(frame: CGRect(x: frame.size.width - 75, y: 0, width: 60, height: 48))
        button.titleLabel?.font = SemiboldFont(size: 16)
        button.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        button.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
        button.setTitle(LocalizableStrings.undo, for: .normal)
        button.contentHorizontalAlignment = .right
        button.addTarget(self, action: #selector(onUndo), for: .touchUpInside)
        addSubview(button)
        
        timer = CountdownView(frame: CGRect(x: 15, y: 10, width: 28, height: 28))
        timer?.delegate = self
        timer?.start(beginingValue: 5)
        addSubview(timer ?? UIView())
        
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(onUndo))
        tapGesture.cancelsTouchesInView = false
        addGestureRecognizer(tapGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    @objc private func onUndo() {
        self.timer?.cancel()
        
        self.done(self.data)

        BMSnackBar.dismiss(canceled: true)
    }
    
    internal func timerDidEnd() {
        self.ended(self.data)

        BMSnackBar.dismiss(canceled: false)
    }
}

extension BMSnackBar {
    
    private static var snack: BMSnackBar?

    public static func show (data:SnackData!, done: @escaping (SnackData?) -> Void, ended: @escaping (SnackData?) -> Void) {
       
        if snack != nil && snack?.data.id == data.id {
            return
        }
        else if snack != nil {
            snack?.ended(snack?.data)
            snack?.removeFromSuperview()
            snack = nil
        }
        
        snack = BMSnackBar(data: data, done: done, ended: ended)
        
        let app = UIApplication.shared.delegate as! AppDelegate
        app.window?.addSubview(snack!)
        
        snack?.popIn()
    }
    
    @objc public static func dismiss(canceled:Bool) {
        if BMSnackBar.snack != nil {
            BMSnackBar.snack?.popOut {
                BMSnackBar.snack?.removeFromSuperview()
                BMSnackBar.snack = nil
            }
        }
    }
}
