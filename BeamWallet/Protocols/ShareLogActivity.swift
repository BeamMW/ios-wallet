//
// ShareLogActivity.swift
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

import Foundation
import MessageUI

class ShareLogActivity: UIActivity {
    
    public var zipUrl:URL!
    
    override class var activityCategory: UIActivity.Category {
        return .action
    }
    override var activityType: UIActivity.ActivityType? {
        guard let bundleId = Bundle.main.bundleIdentifier else {return nil}
        return UIActivity.ActivityType(rawValue: bundleId + "\(self.classForCoder)")
    }
    
    override var activityTitle: String? {
        return "Share to Beam Support"
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "logo_small")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        //
    }
    override func perform() {
        sendMail()
    }
}

extension ShareLogActivity : MFMailComposeViewControllerDelegate {
    func sendMail() {
        if(MFMailComposeViewController.canSendMail()){
            
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients(["support@beam.mw"])
            mailComposer.setSubject(Settings.sharedManager().target == Testnet ? "beam wallet testnet logs" : "beam wallet logs")
            
            if let data = try? Data(contentsOf: self.zipUrl) {
                mailComposer.addAttachmentData(data, mimeType: "application/zip", fileName: "logs.zip")
            }
            
            if let vc = UIApplication.getTopMostViewController() {
                vc.present(mailComposer, animated: true, completion: nil)
            }
        }
        else
        {
            UIApplication.shared.open(URL(string: "mailto:support@beam.mw")!, options: [:]) { (_ ) in
                self.activityDidFinish(true)
            }
        }
    }
    
    func mailComposeController(_ didFinishWithcontroller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        
        didFinishWithcontroller.dismiss(animated: true) {
            self.activityDidFinish(true)
        }
    }
}

