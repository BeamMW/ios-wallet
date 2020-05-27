//
// UnlinkConfirmViewController.swift
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

class UnlinkConfirmViewController: BaseTableViewController {
    
    private lazy var footerView: UIView = {
        var view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 115))
        
        var sendButton = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width-143)/2, y: 40, width: 143, height: 44), color: UIColor.main.brightTeal)
        sendButton.setImage(IconUnlinkSmall(), for: .normal)
        sendButton.setTitle(Localizable.shared.strings.unlink.lowercased(), for: .normal)
        sendButton.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        sendButton.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
        sendButton.addTarget(self, action: #selector(onNext), for: .touchUpInside)
        view.addSubview(sendButton)
        
        
        return view
    }()
    
    private var items = [BMMultiLineItem]()
    
    private var viewModel:UnlinkTransactionViewModel!
    
    init(viewModel:UnlinkTransactionViewModel!) {
        super.init(nibName: nil, bundle: nil)
        
        self.viewModel = viewModel
        self.items.append(contentsOf: self.viewModel.buildBMMultiLineItems())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientTopBar(mainColor: UIColor.main.brightSkyBlue)

        title = Localizable.shared.strings.confirm.uppercased()
        
        tableView.register([BMMultiLinesCell.self, BMFieldCell.self])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        tableView.tableFooterView = footerView
        
        self.viewModel.didChangeCalculated = {[weak self] item in
            guard let strongSelf = self else { return }
            strongSelf.items.insert(item, at: strongSelf.items.count-2)
            strongSelf.tableView.reloadData()
        }
        self.viewModel.calculateChange()
    }
    
    
    @objc private func onNext() {
        view.endEditing(true)
        
        if Settings.sharedManager().isNeedaskPasswordForSend {
            let modalViewController = UnlockPasswordPopover(event: .transaction)
            modalViewController.completion = { [weak self] obj in
                if obj == true {
                    self?.onSend()
                }
            }
            modalViewController.modalPresentationStyle = .overFullScreen
            modalViewController.modalTransitionStyle = .crossDissolve
            self.present(modalViewController, animated: true, completion: nil)
        }
        else{
            onSend()
        }
    }
    
    
    private func onSend() {
        viewModel.send()
        
        if let viewControllers = self.navigationController?.viewControllers{
            for vc in viewControllers {
                if vc is WalletViewController {
                    self.navigationController?.popToViewController(vc, animated: true)
                    return
                }
            }
        }
        self.navigationController?.popToRootViewController(animated: true)
    }
}

extension UnlinkConfirmViewController : UITableViewDelegate {
    
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


extension UnlinkConfirmViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  tableView
            .dequeueReusableCell(withType: BMMultiLinesCell.self, for: indexPath)
            .configured(with: items[indexPath.section])
        
        return cell
    }
}

