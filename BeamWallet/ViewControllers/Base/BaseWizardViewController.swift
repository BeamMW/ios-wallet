//
//  BaseWizardViewController.swift
//  BeamWallet
//
// 3/1/19.
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

class BaseWizardViewController: BaseViewController {

    @IBOutlet weak var stackWidth: NSLayoutConstraint?
    @IBOutlet weak var mainStack: UIStackView?
    @IBOutlet weak var stackY: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Device.screenType == .iPhones_5 {
            stackWidth?.constant = 290
            mainStack?.spacing = 25
            stackY?.constant = 15
        }
        else if Device.screenType == .iPhones_Plus{
            stackY?.constant = 80
            mainStack?.spacing = 60
        }
        else if Device.screenType == .iPhones_X_XS ||
            Device.screenType == .iPhone_XR{
            stackY?.constant = 80
            mainStack?.spacing = 80
        }
        else if Device.screenType == .iPhone_XSMax {
            stackY?.constant = 80
            mainStack?.spacing = 120
            stackWidth?.constant = 340
        }
        
        hideKeyboardWhenTappedAround()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func addCustomBackButton(target:Any?, selector:Selector) {
        let backButton = UIButton(type: .system)
        backButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        backButton.contentHorizontalAlignment = .left
        backButton.tintColor = UIColor.white
        backButton.setImage(IconBack(), for: .normal)
        backButton.addTarget(target, action: selector, for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
}

// MARK: UICollectionViewDelegateFlowLayout

extension BaseWizardViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let noOfCellsInRow = 2
        
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        
        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))
        
        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(noOfCellsInRow))
        
        return CGSize(width: size, height: 38)
    }
}
