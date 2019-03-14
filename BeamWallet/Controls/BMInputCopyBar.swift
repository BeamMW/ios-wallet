//
//  BMInputCopyBar.swift
//  BeamWallet
//
//  Created by Denis on 3/14/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class BMInputCopyBar: UIView {

    var completion : ((String?) -> Void)?
    
    init(frame: CGRect, copy:String) {
        super.init(frame: frame)
        
        let toolBar = UIView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: 44))
        toolBar.backgroundColor = UIColor(red: 186/255, green: 191/255, blue: 196/255, alpha: 1)
        addSubview(toolBar)
        
        let label = UIButton(frame: CGRect(x: 50, y: 5, width: frame.size.width-100, height: 34))
        label.layer.cornerRadius = 6
        label.backgroundColor = UIColor.lightGray
        label.titleLabel?.font = UIFont(name: "SFProDisplay-Regular", size: 14)
        label.setTitleColor(UIColor.black, for: .normal)
        label.setTitleColor(UIColor.gray, for: .highlighted)
        label.setTitle(copy, for: .normal)
        label.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        label.addTarget(self, action: #selector(onCopy), for: .touchUpInside)
        toolBar.addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func onCopy(sender:UIButton) {
        completion?(sender.title(for: .normal))
    }
    
}
