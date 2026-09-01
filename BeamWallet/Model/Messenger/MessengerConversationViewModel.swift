//
// MessengerConversationViewModel.swift
// BeamWallet
//
// Copyright 2026 Beam Development
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

class MessengerConversationViewModel: NSObject {

    public var onDataChanged: (() -> Void)?

    public let peerWalletId: String
    public var myWalletId: String?
    public private(set) var messages: [BMInstantMessage] = []

    init(peerWalletId: String, myWalletId: String? = nil) {
        self.peerWalletId = peerWalletId
        let resolvedMyId = myWalletId
            ?? AppModel.sharedManager().lastMyAddress(forPeer: peerWalletId)
            ?? (AppModel.sharedManager().chats as? [BMChat])?.first { $0.peerWalletId == peerWalletId }?.myWalletId
            ?? (AppModel.sharedManager().walletAddresses as? [BMAddress])?.first { !$0.isExpired() }?.walletId
        self.myWalletId = resolvedMyId
        super.init()

        let cached = AppModel.sharedManager().cachedMessages(forPeer: peerWalletId) as? [BMInstantMessage] ?? []
        messages = cached.sorted { $0.timestamp < $1.timestamp }

        AppModel.sharedManager().addDelegate(self)
    }

    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }

    func load() {
        AppModel.sharedManager().requestMessages(forPeer: peerWalletId)
    }

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let myId = myWalletId, !myId.isEmpty else { return }
        AppModel.sharedManager().sendInstantMessage(peerWalletId, fromAddress: myId, message: trimmed)
    }

    func markAsRead() {
        AppModel.sharedManager().markChat(asRead: peerWalletId)
    }

    func remove() {
        AppModel.sharedManager().removeChat(peerWalletId)
    }
}

extension MessengerConversationViewModel: WalletModelDelegate {

    func onChatMessagesLoaded(_ peerWalletId: String, messages: [BMInstantMessage]) {
        guard peerWalletId == self.peerWalletId else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.messages = messages.sorted { $0.timestamp < $1.timestamp }
            if self.myWalletId == nil || self.myWalletId?.isEmpty == true {
                self.myWalletId = AppModel.sharedManager().lastMyAddress(forPeer: peerWalletId)
            }
            self.onDataChanged?()
        }
    }

    func onInstantMessageReceived(_ message: BMInstantMessage) {
        guard message.peerWalletId == peerWalletId else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let cached = AppModel.sharedManager().cachedMessages(forPeer: self.peerWalletId) as? [BMInstantMessage] ?? []
            self.messages = cached.sorted { $0.timestamp < $1.timestamp }
            self.onDataChanged?()
        }
    }
}
