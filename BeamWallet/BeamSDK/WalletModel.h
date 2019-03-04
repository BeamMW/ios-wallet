//
//  WalletModel.h
//  BeamTest
//
//  Created by Denis on 2/28/19.
//  Copyright © 2019 Denis. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <csignal>

#include "wallet/wallet_client.h"

class WalletModel : public WalletClient
{
public:
    using Ptr = std::shared_ptr<WalletModel>;
    
    WalletModel(beam::IWalletDB::Ptr walletDB, const std::string& nodeAddr);
    ~WalletModel() override;
    
private:
    NSString *GetErrorString(beam::wallet::ErrorType type);

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
    void onPaymentProofExported(const beam::TxID& txID, const beam::ByteBuffer& proof) ;
};
