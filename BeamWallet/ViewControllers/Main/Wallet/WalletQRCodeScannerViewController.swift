//
//  WalletQRCodeScannerViewController.swift
//  BeamWallet
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
import AVFoundation

protocol WalletQRCodeScannerViewControllerDelegate: AnyObject {
    func didScanQRCode(value:String)
}

class WalletQRCodeScannerViewController: UIViewController {

    weak var delegate: WalletQRCodeScannerViewControllerDelegate?

    @IBOutlet private var qrCodeView:V3QRCodeReader!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Scan QR code"
        
        qrCodeView.delegate = self
        qrCodeView.frame = CGRect(x: 0, y: 180, width: UIScreen.main.bounds.size.width, height: self.view.frame.size.height-180);
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        qrCodeView.frame = CGRect(x: 0, y: 180, width: UIScreen.main.bounds.size.width, height: self.view.frame.size.height-180);
        
        checkCameraPermissions()
    }

}

//MARK: - V3QRCodeReaderDelegate

extension WalletQRCodeScannerViewController : V3QRCodeReaderDelegate {
    func getBarCodeData(_ scanDictonary: [AnyHashable : Any]!) {
        
        navigationController?.popViewController(animated: true)
        
        let value = scanDictonary["barCodeValue"] as! String
        
        delegate?.didScanQRCode(value: value)
    }
}


//MARK: - Permissions

extension WalletQRCodeScannerViewController {
    
    private func checkCameraPermissions() {
        let authStatus =  AVCaptureDevice.authorizationStatus(for: .video)
        
        if(authStatus == .authorized) {
            if (!qrCodeView.isRunning()) {
                qrCodeView.startReading()
            }
        }
        else if(authStatus == .notDetermined) {

            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                DispatchQueue.main.async {
                    if granted {
                        if (!self.qrCodeView.isRunning()) {
                            self.qrCodeView.startReading()
                        }
                    }
                    else{
                        self.camDenied()
                    }
                }
            }
        }
        else if (authStatus == .restricted) {
            self.alert(message: "You've been restricted from using the camera on this device. Without camera access this feature won't work. Please contact the device owner so they can give you access")
        }
        else {
            self.camDenied()
        }
    }
    
    private func camDenied() {
        let message = "It looks like your privacy settings are preventing us from accessing your camera to do qr code scanning. You can fix this by doing the following:\n\n1. Touch the Go button below to open the Settings app.\n\n2. Turn the Camera on.\n\n3. Open this app and try again."
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        let openAction = UIAlertAction(title: "Open Settings", style: .default) { (action) in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: { (_ ) in
                 self.navigationController?.popViewController(animated: true)
            })
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            self.navigationController?.popViewController(animated: true)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(openAction)

        self.present(alertController, animated: true, completion: nil)
    }
}



