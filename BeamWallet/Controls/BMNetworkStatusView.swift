//
// BMStatusView.swift
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

class BMNetworkStatusView: UIView {

    private var statusLabel: UILabel!
    public var statusView: UIImageView!
    public var indicatorView:MaterialActivityIndicatorView!
    private var fromNib = false
    private var isPrevUpdate = false
    private var isPrevRecconected = false
    public let changeButton = UIButton()

    public var numberOfLines = 1 {
        didSet {
            statusLabel.backgroundColor = UIColor.clear
            if numberOfLines == 3 {
                statusLabel.numberOfLines = 2
                statusLabel.width = UIScreen.main.bounds.size.width - 180
                statusLabel.h = 36
                statusLabel.y = 0
            }
            else if numberOfLines > 1 {
                statusLabel.numberOfLines = 2
                statusLabel.width = UIScreen.main.bounds.size.width - 130
                statusLabel.h = 36
                statusLabel.y = 0
            }
            else {
                statusLabel.numberOfLines = 1
                statusLabel.width = UIScreen.main.bounds.size.width - 50
                statusLabel.h = 18
                statusLabel.y = !fromNib ? 13 : -2
            }
        }
    }
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 40))
        
        backgroundColor = UIColor.clear
        
        setup(fromNib: false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup(fromNib: true)
    }
    
    
    private func setup(fromNib:Bool) {
        self.fromNib = fromNib
        
        statusView = UIImageView(frame: CGRect(x: !fromNib ? 15 : 0, y: !fromNib ? 17 : 2, width: 12, height: 12))
        statusView.contentMode = .scaleAspectFit
        statusView.layer.cornerRadius = 6
        addSubview(statusView)
        
        statusLabel = UILabel(frame: CGRect(x: !fromNib ? 35 : 20, y: !fromNib ? 13 : -2, width: UIScreen.main.bounds.size.width-50, height: 18))
        statusLabel.font = RegularFont(size: 14)
        statusLabel.numberOfLines = 2
        statusLabel.adjustFontSize = true
        addSubview(statusLabel)
        
        indicatorView = MaterialActivityIndicatorView(frame: statusView.frame)
        indicatorView.color = UIColor.main.green
        addSubview(indicatorView)
        
        changeButton.isHidden = true
        changeButton.addTarget(self, action: #selector(onChangeNode), for: .touchUpInside)
        changeButton.setTitleColor(UIColor.main.green, for: .normal)
        changeButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        changeButton.setTitle(Localizable.shared.strings.change.lowercased(), for: .normal)
        addSubview(changeButton)

        if (AppModel.sharedManager().isUpdating && AppModel.sharedManager().isConnected)
        {
            onSyncProgressUpdated(0, total: 1)
        }
        else if (AppModel.sharedManager().isConnecting)
        {
            onNetwotkStartConnecting(true)
        }
        else if (AppModel.sharedManager().isNodeChanging)
        {
            onNodeStartChanging()
        }
        else{
            onNetwotkStatusChange(AppModel.sharedManager().isConnected)
        }
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        changeButton.frame = CGRect(x: UIScreen.main.bounds.width-75, y: statusView.y - 5, width: 60, height: 18)
        
        statusLabel.y = (statusView.y - (statusLabel.h/2) + 5)
    }
    
    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }
    
    @objc private func onChangeNode() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = SelectNodeViewController()
            //SettingsViewController(type: SettingsViewModel.SettingsType.node)
            top.pushViewController(vc: vc)
        }
    }
    
    private var onlineString:String {
        get {
            if Settings.sharedManager().isNodeProtocolEnabled {
                return  Localizable.shared.strings.online_mobile_node.lowercased()
            }
            else if !Settings.sharedManager().connectToRandomNode {
                return  Localizable.shared.strings.online.lowercased()
            }
            else {
                return Localizable.shared.strings.online.lowercased()
            }
        }
    }
    
    private func changeStatus(connected: Bool) {
        self.changeButton.isHidden = true

        if AppModel.sharedManager().isNodeChanging {
            return
        }

        self.indicatorView.stopAnimating()
        self.statusView.alpha = 1
        self.statusView.layer.borderWidth = 0
        
        self.statusLabel.x = self.fromNib ? 20 : 35
        
        if self.numberOfLines != 3 {
            self.numberOfLines = 1
        }

        if connected {
            
            if AppModel.sharedManager().currencies.count == 0 && Settings.sharedManager().currency != BMCurrencyOff  {
                self.statusView.image = nil
                self.statusView.backgroundColor = UIColor.main.orange
                self.statusView.glow()
                
                self.statusLabel.text = "\(self.onlineString) (exchange rate to \(Settings.sharedManager().currencyName()) wasn’t received)"
                self.statusLabel.textColor = UIColor.main.blueyGrey
            }
            else {
                if !Settings.sharedManager().isNodeProtocolEnabled && !Settings.sharedManager().connectToRandomNode {
                    self.statusView.backgroundColor = UIColor.clear
                    self.statusView.removeGlow()
                    self.statusView.image = UIImage(named: "ic_trusted_node")
                }
                else  {
                    self.statusView.backgroundColor = UIColor.main.green
                    self.statusView.glow()
                }
                
                self.statusLabel.text = self.onlineString
                
                self.statusLabel.textColor = UIColor.main.blueyGrey
            }
            
        }
        else{
            self.statusView.image = nil
            self.statusView.backgroundColor = UIColor.main.red
            self.statusView.glow()
            
            if AppModel.sharedManager().isInternetAvailable == false {
                self.statusLabel.text = Localizable.shared.strings.offline.lowercased()
            }
            else{
                if Settings.sharedManager().isChangedNode() {
                    
                    self.statusLabel.text = Localizable.shared.strings.cannot_connect_node(Settings.sharedManager().nodeAddress)
                    
                    if self.numberOfLines != 3 {
                        self.numberOfLines = 2
                    }

                    self.changeButton.isHidden = false
                }
                else{
                    self.statusLabel.text = Localizable.shared.strings.offline.lowercased()
                }
            }
            
            self.statusLabel.textColor = UIColor.main.red
            
            if self.statusLabel.text == Localizable.shared.strings.offline.lowercased() {
                self.statusLabel.textColor = UIColor.main.blueyGrey
                self.statusView.backgroundColor = UIColor.clear
                self.statusView.layer.borderWidth = 1
                self.statusView.layer.borderColor = UIColor.main.blueyGrey.cgColor
                self.statusView.glow()
            }
        }
    }
}

extension BMNetworkStatusView: WalletModelDelegate {
    
    func onNetwotkStartReconnecting() {
        DispatchQueue.main.async {
            self.isPrevRecconected = true
            self.indicatorView.color = UIColor.main.orange
            self.indicatorView.startAnimating()
            
            self.statusLabel.x = self.fromNib ? 22 : 37
            self.statusLabel.text = Localizable.shared.strings.reconnect.lowercased()
            self.statusView.alpha = 0
            self.statusLabel.textColor = UIColor.main.blueyGrey
        }
    }
    
    func onNetwotkStatusChange(_ connected: Bool) {
        DispatchQueue.main.async {
            let time = (self.isPrevUpdate || self.isPrevRecconected) ? 1.5 : 0
            DispatchQueue.main.asyncAfter(deadline: .now() + time) {
                self.isPrevUpdate = false
                self.isPrevRecconected = false
                self.changeStatus(connected: connected)
            }
        }
    }
    
    func onSyncProgressUpdated(_ done: Int32, total: Int32) {
        
        DispatchQueue.main.async {
            if done != total  {
                let percent = (Double(done)/Double(total)) * 100.0
                
                self.isPrevUpdate = true
                self.indicatorView.color = UIColor.main.green
                self.indicatorView.startAnimating()
                
                self.statusLabel.x = self.fromNib ? 22 : 37
                self.statusLabel.text = Localizable.shared.strings.updating.lowercased() + " \(Int(percent))%"
                self.statusView.alpha = 0
                self.statusLabel.textColor = UIColor.main.blueyGrey
            }
            else {
                let time = (self.isPrevUpdate || self.isPrevRecconected) ? 1.5 : 0
                DispatchQueue.main.asyncAfter(deadline: .now() + time) {
                    self.isPrevUpdate = false
                    self.isPrevRecconected = false
                    if AppModel.sharedManager().isConnecting {
                        self.onNetwotkStartConnecting(true)
                    }
                    else{
                        self.indicatorView.stopAnimating()
                        self.onNetwotkStatusChange(AppModel.sharedManager().isConnected)
                    }
                }
            }
        }
    }
    
    func onNodeStartChanging() {
        DispatchQueue.main.async {
            self.statusView.alpha = 0
            
            self.indicatorView.color = UIColor.main.orange
            self.indicatorView.startAnimating()
            
            self.statusLabel.x = self.fromNib ? 22 : 37
            self.statusLabel.text = Localizable.shared.strings.connecting.lowercased()
            self.statusView.image = nil
            self.statusView.backgroundColor = UIColor.main.orange
            self.statusLabel.textColor = UIColor.main.orange
        }
    }
    
    func onNetwotkStartConnecting(_ connecting: Bool) {
        DispatchQueue.main.async {
            if connecting {
                //https://github.com/BeamMW/ios-wallet/issues/194
                self.onNetwotkStatusChange(true)
            }
        }
    }
}
