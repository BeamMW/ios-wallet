//
//  WalletModel.h
//  BeamTest
//
// 2/28/19.
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

#import <Foundation/Foundation.h>
#include <csignal>

#include "wallet/wallet_client.h"

class WalletModel : public WalletClient
{
public:
    using Ptr = std::shared_ptr<WalletModel>;

    WalletModel(beam::IWalletDB::Ptr walletDB, const std::string& nodeAddr, beam::io::Reactor::Ptr reactor);
    ~WalletModel() override;

private:
    NSString *GetErrorString(beam::wallet::ErrorType type);
    NSString *GetTransactionStatusString(beam::TxDescription transaction);
    NSString *GetTransactionFailurString(beam::TxFailureReason reason);
    NSString *GetUTXOStatusString(beam::Coin coin);
    NSString *GetUTXOTypeString(beam::Coin coin);

    void onStatus(const WalletStatus& status) override;
    void onTxStatus(beam::ChangeAction, const std::vector<beam::TxDescription>& items) override;
    void onSyncProgressUpdated(int done, int total) override;
    void onChangeCalculated(beam::Amount change) override;
    void onAllUtxoChanged(const std::vector<beam::Coin>& utxos) override;
    void onAddresses(bool own, const std::vector<beam::WalletAddress>& addrs) override;
    void onGeneratedNewAddress(const beam::WalletAddress& walletAddr) override;
    void onChangeCurrentWalletIDs(beam::WalletID senderID, beam::WalletID receiverID) override;
    void onNodeConnectionChanged(bool isNodeConnected) override;
    void onWalletError(beam::wallet::ErrorType error) override;
    void FailedToStartWallet() override;
    void onSendMoneyVerified() override;
    void onCantSendToExpired() override;
    void onPaymentProofExported(const beam::TxID& txID, const beam::ByteBuffer& proof) override;
};
