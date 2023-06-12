//
// TransactionViewController.swift
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

class TransactionViewController: UITableViewController {
   
    private var viewModel: DetailTransactionViewModel!
    private var isPreview = false
    private var isPaymentProof = false

    public var transactionId = ""

    override var previewActionItems: [UIPreviewActionItem] {
        let transaction = viewModel.transaction!
        
        var array = [UIPreviewAction]()
        
        if transaction.canSaveContact() {
            let action1 = UIPreviewAction(title: Localizable.shared.strings.save_contact_title,
                                          style: .default,
                                          handler: { _, _ in
                                              self.viewModel.saveContact()
            })
            
            array.append(action1)
        }
        
        let action1 = UIPreviewAction(title: Localizable.shared.strings.share_details,
                                      style: .default,
                                      handler: { _, _ in
                                          self.viewModel.share()
        })
        array.append(action1)
        
        let action2 = UIPreviewAction(title: Localizable.shared.strings.copy_details,
                                      style: .default,
                                      handler: { _, _ in
                                          self.viewModel.copyDetails()
        })
        
        array.append(action2)
        
        if !transaction.isIncome {
            let action3 = UIPreviewAction(title: Localizable.shared.strings.repeat_transaction,
                                          style: .default,
                                          handler: { _, _ in
                                              self.viewModel.repeatTransation(transaction: self.viewModel.transaction!)
            })
            array.append(action3)
        }
        
        if transaction.canCancel {
            let action4 = UIPreviewAction(title: Localizable.shared.strings.cancel_transaction,
                                          style: .default,
                                          handler: { _, _ in
                                              self.viewModel.cancelTransation(indexPath: nil)
            })
            array.append(action4)
        }
        
        if transaction.canDelete {
            let action5 = UIPreviewAction(title: Localizable.shared.strings.delete_transaction,
                                          style: .destructive,
                                          handler: { _, _ in
                                              self.viewModel.deleteTransation(indexPath: nil)
            })
            array.append(action5)
        }
        
        return array
    }
    

    init(transaction: BMTransaction, preview: Bool = false) {
        super.init(nibName: nil, bundle: nil)
        
        isPreview = preview
        transactionId = transaction.id
        viewModel = DetailTransactionViewModel(transaction: transaction)
    }
    
    init(transaction: BMTransaction, isPaymentProof:Bool) {
        super.init(nibName: nil, bundle: nil)
        
        self.isPaymentProof = isPaymentProof
       
        transactionId = transaction.id
        viewModel = DetailTransactionViewModel(transaction: transaction, isPaymentProof: isPaymentProof)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register([BMMultiLinesCell.self, BMDetailAmountCell.self])
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView?.backgroundColor = UIColor.main.marine
        tableView.backgroundColor = UIColor.main.marine
        tableView.separatorStyle = .none
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 40))

        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))
        
        subscribeToUpdates()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    public func didShow() {
    }
    
    private func subscribeToUpdates() {
        viewModel.onDataChanged = { [weak self] in
            UIView.performWithoutAnimation {
                self?.tableView.stopRefreshing()
                self?.tableView.reloadData()
            }
        }
        
        viewModel.onDataUpdated = { [weak self]
            _, transaction in
            AppModel.sharedManager().cancelTransaction(transaction)
            self?.back()
        }
        
        viewModel.onDataDeleted = { [weak self]
            _, transaction in
            AppModel.sharedManager().prepareDeleteTransaction(transaction)
            self?.back()
        }
    }
    
    @objc private func refreshData(_ sender: Any) {
        AppModel.sharedManager().getWalletStatus()
    }
    
    @objc func onMore(sender: UIBarButtonItem) {
        BMPopoverMenu.show(menuArray: viewModel.actionItems(), done: { selectedItem in
            if let item = selectedItem {
                switch item.action {
                case .save_contact:
                    self.viewModel.saveContact()
                case .repeat_transaction:
                    self.viewModel.repeatTransation(transaction: self.viewModel.transaction!)
                case .cancel_transaction:
                    self.viewModel.cancelTransation(indexPath: nil)
                case .delete_transaction:
                    self.viewModel.deleteTransation(indexPath: nil)
                case .share:
                    self.viewModel.share()
                case .copy:
                    self.viewModel.copyDetails()
                case .open_dapp:
                    self.viewModel.openDapp()
                default:
                    return
                }
            }
        }, cancel: {})
    }
}

extension TransactionViewController {
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension TransactionViewController {
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            
            let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
            view.backgroundColor = UIColor.white.withAlphaComponent(0.05)
            
            let line = UIView(frame: CGRect(x: 15, y: view.h/2, width: UIScreen.main.bounds.width - 30, height: 1))
            line.backgroundColor = .white
            line.alpha = 0.1
            view.addSubview(line)
            
            return view
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 40
        }
        
        return 0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return isPaymentProof ? 2 : 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? viewModel.details.count : viewModel.proofDetail.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if let item = viewModel.details[indexPath.row] as? BMMultiLineItem {
                let cell = tableView
                    .dequeueReusableCell(withType: BMMultiLinesCell.self, for: indexPath)
                    .configured(with: item)
                cell.increaseSpace = true
                cell.delegate = self
                cell.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
                cell.addDots()
                return cell
            }
            else if let item = viewModel.details[indexPath.row] as? BMThreeLineItem {
                let cell = tableView
                    .dequeueReusableCell(withType: BMDetailAmountCell.self, for: indexPath)
                cell.increaseSpace = true
                cell.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
                if item.title == Localizable.shared.strings.fee.uppercased() {
                    cell.configure(asset: AssetsManager.shared().getAsset(0), item: item)
                }
                else {
                    if viewModel.transaction?.isMultiAssets() == true {
                        if let asset = item.customObject as? BMAsset {
                            cell.configure(asset: asset, item: item)
                        } else {
                            cell.configure(asset: viewModel.transaction?.asset, item: item)
                        }
                    } else {
                        cell.configure(asset: viewModel.transaction?.asset, item: item)
                    }
                }
                cell.addDots()
                return cell
            }
            else {
                return UITableViewCell()
            }
        }
        else {
            let item = viewModel.proofDetail[indexPath.row]
            
            let cell = tableView
                .dequeueReusableCell(withType: BMMultiLinesCell.self, for: indexPath)
                .configured(with: item)
            cell.increaseSpace = true
            cell.delegate = self
            cell.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
            cell.addDots()

            return cell
        }
    }
}

extension TransactionViewController: TransactionPaymentProofCellDelegate {
    func onPaymentProofDetails() {
        if let proof = viewModel.paymentProof {
            let vc = PaymentProofDetailViewController(transaction: viewModel.transaction!, paymentProof: proof)
            pushViewController(vc: vc)
        }
    }
    
    func onPaymentProofCopy() {
        if let code = viewModel.paymentProof?.code {
            UIPasteboard.general.string = code
            ShowCopied()
        }
    }
}

extension TransactionViewController: GeneralInfoCellDelegate {
    func onClickToCell(cell: UITableViewCell) {
        if let path = tableView.indexPath(for: cell) {
            if let item = viewModel.details[path.row] as? BMMultiLineItem {
                if item.title == Localizable.shared.strings.kernel_id.uppercased() {
                    let kernelId = viewModel.transaction!.kernelId
                    let link = Settings.sharedManager().explorerAddress + kernelId
                    if let url = URL(string: link) {
                        openUrl(url: url)
                    }
                }
            }
        }
    }
}
