//
// SendConfirmViewController.swift
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

class SendConfirmViewController: BaseTableViewController {

    private lazy var footerView: UIView = {
        var view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 115))
        
        var sendButton = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width-180)/2, y: 40, width: 180, height: 44), color: UIColor.main.heliotrope)
        sendButton.setImage(IconSendBlue(), for: .normal)
        sendButton.setTitle(Localizable.shared.strings.send.lowercased(), for: .normal)
        sendButton.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        sendButton.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
        sendButton.addTarget(self, action: #selector(onNext), for: .touchUpInside)
        view.addSubview(sendButton)
        
        return view
    }()
    
    private var items = [BMMultiLineItem]()
    
    private var viewModel:SendTransactionViewModel!
    
    init(viewModel:SendTransactionViewModel!) {
        super.init(nibName: nil, bundle: nil)
        
        self.viewModel = viewModel
        self.items.append(contentsOf: self.viewModel.buildBMMultiLineItems())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.onCalculateChanged = {[weak self] obj in
            self?.onChangeCalculated(obj)
        }
        
        setGradientTopBar(mainColor: UIColor.main.heliotrope)
        
        title = Localizable.shared.strings.confirm.uppercased()
        
        tableView.register([BMMultiLinesCell2.self, BMFieldCell.self])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        tableView.tableFooterView = footerView
        
        viewModel.calculateChange()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Settings.sharedManager().removeDelegate(self)
        AppModel.sharedManager().removeDelegate(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        addRightButton(image: Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance(), target: self, selector: #selector(onHideAmounts))

        AppModel.sharedManager().addDelegate(self)
        Settings.sharedManager().addDelegate(self)
    }
    
    @objc private func onNext() {
        view.endEditing(true)
        
        if Settings.sharedManager().isNeedaskPasswordForSend {
            let modalViewController = UnlockPasswordPopover(event: .transaction)
            modalViewController.completion = { [weak self] obj in
                if obj == true {
                    self?.askForSaveContact()
                }
            }
            modalViewController.modalPresentationStyle = .overFullScreen
            modalViewController.modalTransitionStyle = .crossDissolve
            self.present(modalViewController, animated: true, completion: nil)
        }
        else{
            askForSaveContact()
        }
    }
        
    private func askForSaveContact() {
        if viewModel.isNeedSaveContact() {
            viewModel.saveContact = true

            if var controllers = self.navigationController?.viewControllers {
                controllers.removeLast()
                controllers.removeLast()
                
                let vc = SaveContactViewController(address: self.viewModel.toAddress)
                vc.isFromSendScreen = true
                controllers.append(vc)
                self.navigationController?.setViewControllers(controllers, animated: true)
            }

            self.onSend(needBack: false)
        }
        else{
            viewModel.saveContact = false
            
            self.onSend(needBack: true)
        }
    }
    
    private func onSend(needBack:Bool) {
        viewModel.send()
        
        if needBack {
            if let viewControllers = self.navigationController?.viewControllers{
                for vc in viewControllers {
                    if vc is WalletViewController {
                        self.navigationController?.popToViewController(vc, animated: true)
                        return
                    }
                    else if vc is AddressViewController {
                        self.navigationController?.popToViewController(vc, animated: true)
                        return
                    }
                }
            }
            
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
}

extension SendConfirmViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section > 0) ? 20 : 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


extension SendConfirmViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  tableView
            .dequeueReusableCell(withType: BMMultiLinesCell2.self, for: indexPath)
            .configured(with: items[indexPath.section])
        
        return cell
    }
}

extension SendConfirmViewController: WalletModelDelegate {
    
    func onChangeCalculated(_ amount: Double) {
        DispatchQueue.main.async { [self] in
            if !Settings.sharedManager().isHideAmounts {
                
                let asset = (AssetsManager.shared().getAsset(Int32(self.viewModel.selectedAssetId)))
                let assetName = (asset?.unitName ?? "")
                
                let totalString = (self.viewModel.selectedAssetId == 0 ? String.currency(value: (amount), name: assetName) : String.currency(value: (0.0), name: assetName)).replacingOccurrences(of: assetName, with: "").replacingOccurrences(of: " ", with: "")
                
                let totalDetail = self.viewModel.amountString(amount: totalString, isFee: false, assetId: viewModel.selectedAssetId, color: UIColor.white, doubleAmount: amount)
                
                let item = BMMultiLineItem(title: Localizable.shared.strings.change, detail: totalDetail.string, detailFont: SemiboldFont(size: 16), detailColor: UIColor.white)
                item.detailAttributedString = totalDetail
                self.items.append(item)
              
                let total = AppModel.sharedManager().realTotal(Double(self.viewModel.amount) ?? 0, fee: Double(self.viewModel.fee) ?? 0, assetId: Int32(self.viewModel.selectedAssetId))
                let left = (asset?.realAmount ?? 0.0) - total
                let leftString = String.currency(value: left, name: assetName).replacingOccurrences(of: assetName, with: "")
                
                let leftDetail = self.viewModel.amountString(amount: leftString, isFee: false, assetId: viewModel.selectedAssetId, color: UIColor.white, doubleAmount: left)
               
                let leftItem = BMMultiLineItem(title: Localizable.shared.strings.remaining.uppercased(), detail: leftDetail.string, detailFont: SemiboldFont(size: 16), detailColor: UIColor.white)
                leftItem.detailAttributedString = leftDetail
                self.items.append(leftItem)
                
                if self.viewModel.selectedAssetId != 0 {
                    let beamAsset = (AssetsManager.shared().getAsset(Int32(0)))
                    let total = AppModel.sharedManager().remainingBeam(Double(beamAsset?.realAmount ?? 0), fee: Double(self.viewModel.fee) ?? 0)

                    let leftString = String.currency(value: total, name: beamAsset?.unitName ?? "").replacingOccurrences(of: "BEAM", with: "")
                    let leftDetail = self.viewModel.amountString(amount: leftString, isFee: false, assetId: 0, color: UIColor.white, doubleAmount: left)
                    
                    let leftItem = BMMultiLineItem(title: Localizable.shared.strings.remaining_beam.uppercased(), detail: leftDetail.string, detailFont: SemiboldFont(size: 16), detailColor: UIColor.white)
                    leftItem.detailAttributedString = leftDetail
                    self.items.append(leftItem)
                }

                self.tableView.reloadData()
            }
        }
    }
}

extension SendConfirmViewController: SettingsModelDelegate {
    
    func onChangeHideAmounts() {
        addRightButton(image: Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance(), target: self, selector: #selector(onHideAmounts))

        self.items.removeAll()
        self.items.append(contentsOf: self.viewModel.buildBMMultiLineItems())
        self.tableView.reloadData()
        
        self.viewModel.calculateChange()
    }
}
