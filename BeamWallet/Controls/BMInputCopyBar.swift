//
// BMInputCopyBar.swift
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

class BMInputCopyBar: UIView {

    var completion : ((String?) -> Void)?
    
    init(frame: CGRect, copy:String) {
        super.init(frame: frame)
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: 44))
        view.backgroundColor = UIColor.clear
        addSubview(view)
        
        let toolbar = UIToolbar(frame: view.bounds)
        toolbar.autoresizingMask = .flexibleWidth;
        toolbar.isUserInteractionEnabled = false;
        view.addSubview(toolbar)
        
        let separator = UIView(frame: CGRect(x:0, y:43.5, width:view.frame.size.width, height:0.5))
        separator.autoresizingMask = .flexibleWidth;
        separator.backgroundColor = UIColor.init(white: 0, alpha: 0.2)
        view.addSubview(separator)
        
        let label = UIButton(frame: CGRect(x: 50, y: 5, width: frame.size.width-100, height: 34))
        label.layer.cornerRadius = 6
        label.backgroundColor = UIColor.lightGray
        label.titleLabel?.font = RegularFont(size: 14)
        label.setTitleColor(UIColor.black, for: .normal)
        label.setTitleColor(UIColor.gray, for: .highlighted)
        label.setTitle(copy, for: .normal)
        label.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        label.addTarget(self, action: #selector(onCopy), for: .touchUpInside)
        view.addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizables.shared.strings.fatalInitCoderError)
    }
    
    @objc private func onCopy(sender:UIButton) {
        completion?(sender.title(for: .normal))
    }
    
}
