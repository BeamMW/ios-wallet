//
// MessengerChatListViewModel.swift
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

class MessengerChatListViewModel: NSObject {

    public var onDataChanged: (() -> Void)?

    public var chats: [BMChat] {
        return AppModel.sharedManager().chats as? [BMChat] ?? []
    }

    override init() {
        super.init()
        AppModel.sharedManager().addDelegate(self)
    }

    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }

    func reload() {
        AppModel.sharedManager().requestChats()
    }

    func remove(at index: Int) {
        guard index >= 0, index < chats.count else { return }
        let peer = chats[index].peerWalletId
        AppModel.sharedManager().removeChat(peer)
    }
}

extension MessengerChatListViewModel: WalletModelDelegate {
    func onChatListChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.onDataChanged?()
        }
    }

    func onInstantMessageReceived(_ message: BMInstantMessage) {
        DispatchQueue.main.async { [weak self] in
            self?.onDataChanged?()
        }
    }

    func onChatRemoved(_ peerWalletId: String) {
        DispatchQueue.main.async { [weak self] in
            self?.onDataChanged?()
        }
    }
}
