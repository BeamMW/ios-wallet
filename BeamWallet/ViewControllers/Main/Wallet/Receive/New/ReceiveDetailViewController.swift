//
// ReceiveDetailViewController.swift
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

class ReceiveDetailViewController: BaseTableViewController {

    private var address:BMAddress!
    private var amount:String?
    private var isRequestedAmount = false
    
    init(address:BMAddress) {
        super.init(nibName: nil, bundle: nil)
        
        self.address = address
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.title = LocalizableStrings.receive.uppercased()

        tableView.register([ReceiveAddressCell.self, ReceiveAddressCommentCell.self, ReceiveAddressRequestAmountCell.self, ReceiveAddressButtonsCell.self, ReceiveAddressRequestedAmountCell.self])
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        
        addLeftButton(image: IconBack(), target: self, selector: #selector(onBack))
     //   addRightButton(image: Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance(), target: self, selector: #selector(onHideAmounts))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification , object: nil)
    }
    
    @objc private func onHideAmounts(sender:UIButton) {
        
    }
    
    @objc private func onBack(sender:UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

extension ReceiveDetailViewController : UITableViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.didScroll(scrollView: scrollView)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 0
        default:
            return 40
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension ReceiveDetailViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        switch indexPath.section {
        case 0:
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveAddressCell.self, for: indexPath)
                .configured(with: address)
            return cell
        case 1:
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveAddressCommentCell.self, for: indexPath)
                .configured(with: address)
            cell.delegate = self
            return cell
        case 2:
            if isRequestedAmount {
                let cell = tableView
                    .dequeueReusableCell(withType: ReceiveAddressRequestedAmountCell.self, for: indexPath)
                cell.delegate = self
                return cell
            }
            else{
                let cell = tableView
                    .dequeueReusableCell(withType: ReceiveAddressRequestAmountCell.self, for: indexPath)
                cell.delegate = self
                return cell
            }
        case 3:
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveAddressButtonsCell.self, for: indexPath)
            cell.delegate = self
            return cell
        default:
            return BaseCell()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
}

extension ReceiveDetailViewController : ReceiveCellProtocol {
    
    func textValueDidBegin(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender) {
            tableView.scrollToRow(at: path, at: .top, animated: true)
        }
    }
    
    func textValueDidChange(_ sender: UITableViewCell, _ text: String) {
        if sender is ReceiveAddressCommentCell {
            address.label = text
        }
        else if sender is ReceiveAddressRequestedAmountCell {
            amount = text
        }
    }
    
    func textValueDidReturn(_ sender: UITableViewCell) {
        if sender is ReceiveAddressCommentCell {
            AppModel.sharedManager().setWalletComment(address.label, toAddress: address.walletId)
        }
    }

    func onClickRequest() {
        isRequestedAmount = true
        
        if let indexPath = tableView.findPath(ReceiveAddressRequestAmountCell.self) {
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
    func onClickRemoveRequest() {
        isRequestedAmount = false

        amount = nil

        if let indexPath = tableView.findPath(ReceiveAddressRequestedAmountCell.self) {
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
    func onClickQRCode() {
        let modalViewController = WalletQRCodeViewController(address: address, amount: amount)
        modalViewController.delegate = self
        modalViewController.modalPresentationStyle = .overFullScreen
        modalViewController.modalTransitionStyle = .crossDissolve
        present(modalViewController, animated: true, completion: nil)
    }
    
    func onClickShare() {
        let vc = UIActivityViewController(activityItems: [address.walletId ?? String.empty()], applicationActivities: [])
        vc.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            if completed {
                self.navigationController?.popViewController(animated: true)
                return
            }
        }
        vc.excludedActivityTypes = [UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.print,UIActivity.ActivityType.openInIBooks]
        present(vc, animated: true)
    }
}

extension ReceiveDetailViewController : WalletQRCodeViewControllerDelegate {
    
    func onCopyDone() {
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: Keyboard Handling

extension ReceiveDetailViewController {
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = UIEdgeInsets.zero
    }
}
