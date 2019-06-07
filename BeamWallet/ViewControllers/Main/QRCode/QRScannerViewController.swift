//
// QRScannerViewController.swift
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
import AVFoundation

protocol QRScannerViewControllerDelegate: AnyObject {
    func didScanQRCode(value:String, amount:String?)
}

class QRScannerViewController: BaseViewController {

    weak var delegate: QRScannerViewControllerDelegate?
    
    @IBOutlet private weak var scannerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var titleLabelY: NSLayoutConstraint!

    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!

    private var offset:CGFloat = 140
    private var scannedValue:String = ""
    public var isBotScanner = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isGradient {
            titleLabelY.constant = 80
            titleLabel.text = titleLabel.text?.uppercased()
            titleLabel.letterSpacing = 1.5
            
            offset = 180
            
            setGradientTopBar(mainColor: UIColor.main.heliotrope, addedStatusView: false)
        }
     
        title = isBotScanner ? LocalizableStrings.scan_tg_qr_code : LocalizableStrings.scan_qr_code

        
        scannerView.frame = CGRect(x: 0, y: offset, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height-offset)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkCameraPermissions()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    private func initSession() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .qr, .aztec, .code128]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = scannerView.bounds
        previewLayer.videoGravity = .resizeAspectFill
        scannerView.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    private func detectQRCode(_ image: UIImage?) -> [CIFeature]? {

        if let image = image, let ciImage = CIImage.init(image: image){
            var options: [String: Any]
            let context = CIContext()
            options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
            let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options)
            if ciImage.properties.keys.contains((kCGImagePropertyOrientation as String)){
                options = [CIDetectorImageOrientation: ciImage.properties[(kCGImagePropertyOrientation as String)] ?? 1]
            }else {
                options = [CIDetectorImageOrientation: 1]
            }
            let features = qrDetector?.features(in: ciImage, options: options)
            return features
            
        }
        return nil
    }

}

//MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRScannerViewController : AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            getBarCodeData(code: stringValue)
        }

    }
    
    private func showError() {
        BMToast.show(text: LocalizableStrings.error_scan_qr_code)
      
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.scannedValue = ""
        }
    }
    
    private func getBarCodeData(code: String) {
        
        if (scannedValue.isEmpty)
        {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

            scannedValue = code;
            
            if isBotScanner {
                do {
                    if let json = try JSONSerialization.jsonObject(with: scannedValue.data(using: .utf8)!, options: .mutableContainers) as? [String: Any] {
                        print(json)
                        
                        if (json["_id"] as? u_quad_t) != nil {
                            navigationController?.popViewController(animated: true)
                            
                            delegate?.didScanQRCode(value: scannedValue, amount: nil)
                        }
                    }
                    else{
                        self.showError()
                    }
                } catch _ {
                    self.showError()
                }
            }
            else{
                var address = code
                var amount:String?
                
                if(address.hasPrefix("beam:"))
                {
                    let removePrefix = address.replacingOccurrences(of: "beam:", with: "")
                    
                    if (removePrefix.contains("?")) {
                        let url = URL(string: removePrefix)
                        let params = url?.queryParameters
                        
                        if let a = params?["amount"] {
                            amount = a
                        }
                        
                        if let index = removePrefix.firstIndex(of: "?") {
                            address = String(removePrefix[..<index])
                        }
                    }
                    else {
                       address = removePrefix
                    }
                }
                
                if (!AppModel.sharedManager().isValidAddress(address))
                {
                    self.showError()
                }
                else{
                    navigationController?.popViewController(animated: true)
                    
                    delegate?.didScanQRCode(value: address, amount: amount)
                }
            }
        }
    }
}


//MARK: - Permissions

extension QRScannerViewController {
    
    private func checkCameraPermissions() {
        let authStatus =  AVCaptureDevice.authorizationStatus(for: .video)
        
        if(authStatus == .authorized) {
            initSession()
        }
        else if(authStatus == .notDetermined) {

            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                DispatchQueue.main.async {
                    if granted {
                        self.initSession()
                    }
                    else{
                        self.camDenied()
                    }
                }
            }
        }
        else if (authStatus == .restricted) {
            self.alert(message: LocalizableStrings.camera_restricted)
        }
        else {
            self.camDenied()
        }
    }
    
    private func camDenied() {
        self.confirmAlert(title: String.empty(), message: LocalizableStrings.camera_denied_text, cancelTitle: LocalizableStrings.cancel, confirmTitle: LocalizableStrings.open_settings, cancelHandler: { (_ ) in
            
        }) { (_ ) in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: { (_ ) in
                self.navigationController?.popViewController(animated: true)
            })
        }
    }
}
