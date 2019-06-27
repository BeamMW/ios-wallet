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

    enum ScanType: Int {
        case beam = 0
        case tg_bot = 1
        case bitcoin = 2
        case ethereum = 3
        case litecoin = 4
    }
    
    weak var delegate: QRScannerViewControllerDelegate?
    
    @IBOutlet private weak var scannerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var titleLabelY: NSLayoutConstraint!

    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!

    private var offset:CGFloat = 140
    private var scannedValue:String = ""
    
    public var scanType = ScanType.beam
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isGradient {
            titleLabelY.constant = 80
            titleLabel.text = titleLabel.text?.uppercased()
            titleLabel.letterSpacing = 1.5
            
            offset = 180
            
            setGradientTopBar(mainColor: UIColor.main.heliotrope, addedStatusView: false)
        }
        
        switch scanType {
        case .tg_bot:
            title = Localizable.shared.strings.scan_tg_qr_code
        case .bitcoin:
            title = Localizable.shared.strings.scan_qr_code
            titleLabel.text = Localizable.shared.strings.scan_btc_qr_code.uppercased()
        case .litecoin:
            title = Localizable.shared.strings.scan_qr_code
            titleLabel.text = Localizable.shared.strings.scan_ltc_qr_code.uppercased()
        case .ethereum:
            title = Localizable.shared.strings.scan_qr_code
            titleLabel.text = Localizable.shared.strings.scan_eth_qr_code.uppercased()
        default:
            title = Localizable.shared.strings.scan_qr_code
            titleLabel.text = Localizable.shared.strings.scan_receiver_qr_code.uppercased()
        }
        
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
        BMToast.show(text: Localizable.shared.strings.error_scan_qr_code)
      
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.scannedValue = ""
        }
    }
    
    private func getBarCodeData(code: String) {
        
        if (scannedValue.isEmpty)
        {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

            scannedValue = code;
            
            print(scannedValue)
            
            if scanType == .tg_bot {
                do {
                    if let json = try JSONSerialization.jsonObject(with: scannedValue.data(using: .utf8)!, options: .mutableContainers) as? [String: Any] {
                        print(json)
                        
                        if (json["_id"] as? u_quad_t) != nil {
                            back()
                            
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
            else if scanType == .bitcoin || scanType == .litecoin {
                if(scannedValue.hasPrefix("bitcoin:"))
                {
                    let split = scannedValue.split(separator: ":")
                    if split.count >= 2 {
                        var address = String(split[1])
                        if address.contains("?") {
                            address = String(address.split(separator: "?")[0])
                        }
                        back()
                        delegate?.didScanQRCode(value:address , amount: nil)
                    }
                    else{
                        self.showError()
                    }
                }
                else{
                    self.showError()
                }
            }
            else if scanType == .ethereum {
                if(scannedValue.hasPrefix("0x"))
                {
                    delegate?.didScanQRCode(value: scannedValue, amount: nil)
                }
                else{
                    self.showError()
                }
            }
            else if scanType == .beam {
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
                    back()
                    
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
            self.alert(message: Localizable.shared.strings.camera_restricted)
        }
        else {
            self.camDenied()
        }
    }
    
    private func camDenied() {
        self.confirmAlert(title: String.empty(), message: Localizable.shared.strings.camera_denied_text, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.open_settings, cancelHandler: { (_ ) in
            
        }) { (_ ) in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: { (_ ) in
                self.back()
            })
        }
    }
}
