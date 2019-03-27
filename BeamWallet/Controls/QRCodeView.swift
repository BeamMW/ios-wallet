//
//  QRCodeView.swift
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

class QRCodeView: UIView {
    private lazy var filter = CIFilter(name: "CIQRCodeGenerator")
    private lazy var imageView = UIImageView()
    private lazy var indicator = UIActivityIndicatorView(style: .white)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        indicator.hidesWhenStopped = true
        
        addSubview(imageView)
        addSubview(indicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        indicator.hidesWhenStopped = true
        
        addSubview(imageView)
        addSubview(indicator)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = bounds
        indicator.center = imageView.center
    }
    
    func getImage() -> UIImage? {
        return self.imageView.image
    }
    
    func generateCode(_ string: String, foregroundColor: UIColor = .black, backgroundColor: UIColor = .white) {
        
        indicator.startAnimating()
        
        DispatchQueue.global(qos: .background).async {
            guard let filter = self.filter,
                let data = string.data(using: .isoLatin1, allowLossyConversion: false) else {
                    return
            }
            
            filter.setValue(data, forKey: "inputMessage")
            
            guard let ciImage = filter.outputImage else {
                return
            }
            
            let transformed = ciImage.transformed(by: CGAffineTransform.init(scaleX: 10, y: 10))
            
            
            let alphaFilter = CIFilter(name: "CIMaskToAlpha")
            alphaFilter?.setValue(transformed, forKey: kCIInputImageKey)
            
            let outImage = alphaFilter?.outputImage
            
            DispatchQueue.main.async {
                self.indicator.stopAnimating()

                if let outputImage = outImage  {
                    self.imageView.tintColor = foregroundColor
                    self.imageView.backgroundColor = backgroundColor
                    self.imageView.image = UIImage(ciImage: outputImage, scale: 2.0, orientation: .up)
                        .withRenderingMode(.alwaysTemplate)
                }
            }
        }
        
     
    }
}
