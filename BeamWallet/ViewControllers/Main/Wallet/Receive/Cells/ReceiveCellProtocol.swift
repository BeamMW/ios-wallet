//
// ReceiveCellProtocol.swift
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

@objc protocol ReceiveCellProtocol: AnyObject {
    @objc optional func textValueDidChange(_ sender: UITableViewCell, _ text:String)
    @objc optional func textValueDidReturn(_ sender: UITableViewCell)
    @objc optional func textValueDidBegin(_ sender: UITableViewCell)
    
    @objc optional func onClickQRCode()
    @objc optional func onClickShare()
    
    @objc optional func onChangeAddress()
    
    @objc optional func onConfirmCreate()
    @objc optional func onCancelCreate()
    
    @objc optional func onExpandRecieveAddress(_ sender: UITableViewCell)
    
}
