//
//  DAOConfirmViewController.swift
//  BeamWallet
//
//  Created by Denis on 06.09.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

import UIKit

class DAOConfirmViewController: BaseTableViewController {

    private lazy var footerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 170))
        
        let mainView = UIView(frame: CGRect(x: (UIScreen.main.bounds.size.width-(Device.isLarge ? 320 : 300))/2, y: 90, width: (Device.isLarge ? 320 : 300), height: 44))
        
        let buttonCancel = BMButton.defaultButton(frame: CGRect(x:0, y: 0, width: 143, height: 44), color: UIColor.main.marineThree)
        buttonCancel.setImage(IconCancel(), for: .normal)
        buttonCancel.setTitle(Localizable.shared.strings.cancel.lowercased(), for: .normal)
        buttonCancel.setTitleColor(UIColor.white, for: .normal)
        buttonCancel.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        buttonCancel.addTarget(self, action: #selector(onCancelClicked), for: .touchUpInside)
        mainView.addSubview(buttonCancel)
        
        let buttonConfirm = BMButton.defaultButton(frame: CGRect(x: mainView.frame.size.width - 143, y: 0, width: 143, height: 44), color: (!viewModel.isSpend ? UIColor.main.brightSkyBlue : UIColor.main.heliotrope))
        buttonConfirm.setImage(IconDoneBlue(), for: .normal)
        buttonConfirm.setTitle(Localizable.shared.strings.confirm_accept.lowercased(), for: .normal)
        buttonConfirm.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        buttonConfirm.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
        buttonConfirm.addTarget(self, action: #selector(onConfirmClicked), for: .touchUpInside)
        mainView.addSubview(buttonConfirm)
        
        view.addSubview(mainView)
        
        let infoLabel = UILabel()
        infoLabel.frame = CGRect(x: 20, y: 20, width: UIScreen.main.bounds.width-40, height: 0)
        infoLabel.numberOfLines = 0
        infoLabel.font = ItalicFont(size: 16)
        infoLabel.textAlignment = .center
        if viewModel.isSpend {
            infoLabel.text = String.init(format: Localizable.shared.strings.will_take_funds, app.name)
        }
        else {
            infoLabel.text = String.init(format: Localizable.shared.strings.will_send_funds, app.name)
        }
        if Settings.sharedManager().isDarkMode {
            infoLabel.textColor = UIColor.main.steel;
        }
        else {
            infoLabel.textColor = UIColor.main.blueyGrey
        }
        infoLabel.adjustFontSize = true
        infoLabel.sizeToFit()
        infoLabel.frame = CGRect(x: 20, y: 35, width: UIScreen.main.bounds.width-40, height: infoLabel.frame.size.height)
        
        view.addSubview(infoLabel)
        
        return view
    }()
    
    @objc public var onConfirm: (() -> Void)?
    @objc public var onReject: (() -> Void)?
    @objc public var infoJson:String!
    @objc public var amountJson:String!
    @objc public var app:BMApp!

    private var viewModel: DAOConfirmViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = DAOConfirmViewModel(infoJson: infoJson, amountJson: amountJson)
        
        if !viewModel.isSpend {
            setGradientTopBar(mainColor: UIColor.main.brightSkyBlue)
        }
        else {
            setGradientTopBar(mainColor: UIColor.main.heliotrope)
        }
        
        title = Localizable.shared.strings.confirm.uppercased()
        
        tableView.register([BMMultiLinesCell2.self, BMFieldCell.self])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        tableView.tableFooterView = footerView
    }
    
    
    @objc private func onCancelClicked() {
        self.onReject?()
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func onConfirmClicked() {
        self.onConfirm?()
        self.navigationController?.popViewController(animated: true)
    }
}


extension DAOConfirmViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


extension DAOConfirmViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  tableView
            .dequeueReusableCell(withType: BMMultiLinesCell2.self, for: indexPath)
            .configured(with: viewModel.items[indexPath.section])
        
        return cell
    }
}
