//
// NotificationVersionViewController.swift
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

class NotificationVersionViewController: BaseViewController {
    
    @IBOutlet private weak var versionLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!

    private var version:String!
    
    init(version: String) {
        super.init(nibName: nil, bundle: nil)
        self.version = version
    }
    
    required init?(coder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        
        title = Localizable.shared.strings.notification
        
        topOffset?.constant = (topOffset?.constant ?? 20) - 20
        
        versionLabel.text = Localizable.shared.strings.new_version_available_title(version: version)
        detailLabel.text = Localizable.shared.strings.new_version_available_detail(version: "v\(UIApplication.appVersion())")
    }
    
    @IBAction func onNext(sender: UIButton) {
        AppStoreReviewManager.openAppStorePage()
    }
}

