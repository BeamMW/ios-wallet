//
//  BaseWizardViewController.swift
//  BeamWallet
//
//  Created by Denis on 3/1/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class BaseWizardViewController: UIViewController {

    @IBOutlet weak var stackWidth: NSLayoutConstraint?
    @IBOutlet weak var mainStack: UIStackView?
    @IBOutlet weak var stackY: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Device.screenType == .iPhones_5_5s_5c_SE {
            stackWidth?.constant = 290
            mainStack?.spacing = 25
            stackY?.constant = 15
        }
        else if Device.screenType == .iPhones_6Plus_6sPlus_7Plus_8Plus{
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
