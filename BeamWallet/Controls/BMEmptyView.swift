//
// BMEmptyView.swift
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

class BMEmptyView: UIView {
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var imageView: UIImageView!

    public var text: String? {
        didSet {
            textLabel.text = text
            if Settings.sharedManager().isDarkMode {
                textLabel.textColor = UIColor.main.steel
            }
        }
    }

    public var image: UIImage? {
        didSet {
            if Settings.sharedManager().isDarkMode {
                imageView.image = image?.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = UIColor.main.steel
            }
            else {
                imageView.image = image
            }
        }
    }
}
