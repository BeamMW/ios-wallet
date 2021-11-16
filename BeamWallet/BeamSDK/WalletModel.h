//
// WalletModel.h
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

#import <Foundation/Foundation.h>
#import "RecoveryProgress.h"
#include <csignal>

#include "wallet/core/common.h"
#include "wallet/client/wallet_client.h"
#include <set>

class WalletModel : public beam::wallet::WalletClient
{
public:
    using Ptr = std::shared_ptr<WalletModel>;

  //  WalletClient(const beam::Rules& rules, beam::wallet::IWalletDB::Ptr walletDB, const std::string& nodeAddr, beam::io::Reactor::Ptr reactor);
    WalletModel(beam::wallet::IWalletDB::Ptr walletDB, const std::string& nodeAddr, beam::io::Reactor::Ptr reactor);
    ~WalletModel() override;
    

    bool pre_connected_status;
    RecoveryProgress recoveryProgress;

    std::vector<beam::wallet::WalletAddress> ownAddresses;
    std::vector<beam::wallet::WalletAddress> contacts;
    std::map<uint64_t, beam::wallet::ShieldedCoin> shieldedCoins;

private:
    NSString *GetAddressTo(beam::wallet::TxDescription transaction);
    NSString *GetAddressFrom(beam::wallet::TxDescription transaction);
    NSString *GetErrorString(beam::wallet::ErrorType type);
    NSString *GetTransactionStatusString(beam::wallet::TxDescription transaction);
    NSString *GetTransactionFailurString(beam::wallet::TxFailureReason reason);
    NSString *GetUTXOStatusString(beam::wallet::Coin coin);
    NSString *GetUTXOTypeString(beam::wallet::Coin coin);
    NSString *GetShildedUTXOStatusString(beam::wallet::ShieldedCoin coin);
    NSString *GetShildedUTXOTypeString(beam::wallet::ShieldedCoin coin);
    int getCurrency(beam::wallet::Currency currency);
    
    void doFunction(const std::function<void()>& func);
    void onWalletStatusInternal(const beam::wallet::WalletStatus& newStatus);
    void onStatus(const beam::wallet::WalletStatus& status) override;
    void onTxStatus(beam::wallet::ChangeAction, const std::vector<beam::wallet::TxDescription>& items) override;
    void onSyncProgressUpdated(int done, int total) override;
    void onNormalCoinsChanged(beam::wallet::ChangeAction, const std::vector<beam::wallet::Coin>& utxos) override;
    void onShieldedCoinChanged(beam::wallet::ChangeAction, const std::vector<beam::wallet::ShieldedCoin>& items) override;
    void onAddresses(bool own, const std::vector<beam::wallet::WalletAddress>& addrs) override;
    void onGeneratedNewAddress(const beam::wallet::WalletAddress& walletAddr) override;
    void onNewAddressFailed() override;
    void onNodeConnectionChanged(bool isNodeConnected) override;
    void onWalletError(beam::wallet::ErrorType error) override;
    void FailedToStartWallet() override;
    void onSendMoneyVerified() override;
    void onCantSendToExpired() override;
    void onPaymentProofExported(const beam::wallet::TxID& txID, const beam::ByteBuffer& proof) override;
    void onCoinsByTx(const std::vector<beam::wallet::Coin>& coins) override;
    void onAddressChecked(const std::string& addr, bool isValid) override;
    void onImportRecoveryProgress(uint64_t done, uint64_t total) override;
    void onGetAddress(const beam::wallet::WalletID& wid, const boost::optional<beam::wallet::WalletAddress>& address, size_t offlinePayments) override;
    void onChangeCalculated(beam::Amount changeAsset, beam::Amount changeBeam, beam::Asset::ID assetId) override;
    void onExchangeRates(const std::vector<beam::wallet::ExchangeRate>&) override;
    void onNotificationsChanged(beam::wallet::ChangeAction, const std::vector<beam::wallet::Notification>&) override;
    void onImportDataFromJson(bool isOk) override;
    void onExportDataToJson(const std::string& data) override;
    void onPostFunctionToClientContext(MessageFunction&& func) override;
    void onExportTxHistoryToCsv(const std::string& data) override;
    void onAddressesChanged(beam::wallet::ChangeAction, const std::vector<beam::wallet::WalletAddress>& addresses) override;
    void onPublicAddress(const std::string& publicAddr) override;
    void onAssetInfo(beam::Asset::ID assetId, const beam::wallet::WalletAsset&) override;
    void onCoinsSelected(const beam::wallet::CoinsSelectionInfo&) override;
};
