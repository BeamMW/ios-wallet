//
// WalletModel.m
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

#import "WalletModel.h"
#import "AppModel.h"

#include <boost/regex.hpp>
#include <boost/optional.hpp>

#include "utility/logger.h"
#include "utility/bridge.h"
#include "utility/io/asyncevent.h"
#include "utility/helpers.h"
#include "utility/common.h"
#include "wallet/core/strings_resources.h"

#import "StringStd.h"

using namespace beam;
using namespace beam::io;
using namespace beam::wallet;
using namespace std;


NSString *const AppErrorDomain = @"beam.mw";
NSTimer *timer;

namespace
{
    const size_t kShieldedPer24hFilterSize = 20;
    const size_t kShieldedPer24hFilterBlocksForUpdate = 144;
}

WalletModel::WalletModel(IWalletDB::Ptr walletDB, const std::string& nodeAddr, beam::io::Reactor::Ptr reactor)
: WalletClient(Rules::get(), walletDB, nodeAddr, reactor)
{
    pre_connected_status = true;
}

WalletModel::~WalletModel()
{
    stopReactor();
}

std::string txIDToString(const TxID& txId)
{
    return to_hex(txId.data(), txId.size());
}

void WalletModel::onStatus(const WalletStatus& status)
{
    NSLog(@"onStatus");
        
    auto beamStatus = status.GetBeamStatus();
    
    BMWalletStatus *walletStatus = [[BMWalletStatus alloc] init];
    walletStatus.available = AmountBig::get_Lo(beamStatus.available) + AmountBig::get_Lo(beamStatus.shielded);
    walletStatus.receiving = AmountBig::get_Lo(beamStatus.receiving);
    walletStatus.maturing = AmountBig::get_Lo(beamStatus.maturing);
    walletStatus.sending = AmountBig::get_Lo(beamStatus.sending);
    walletStatus.shielded = AmountBig::get_Lo(beamStatus.shielded);
    walletStatus.maxPrivacy = AmountBig::get_Lo(beamStatus.maturingMP);

    walletStatus.realAmount = (double(int64_t(AmountBig::get_Lo(beamStatus.available))) / Rules::Coin) + (double(int64_t(AmountBig::get_Lo(beamStatus.shielded))) / Rules::Coin);
    walletStatus.realMaturing = double(int64_t(AmountBig::get_Lo(beamStatus.maturing))) / Rules::Coin;
    walletStatus.realSending = double(int64_t(AmountBig::get_Lo(beamStatus.sending))) / Rules::Coin;
    walletStatus.realReceiving = double(int64_t(AmountBig::get_Lo(beamStatus.receiving))) / Rules::Coin;
    walletStatus.realShielded = double(int64_t(AmountBig::get_Lo(beamStatus.shielded))) / Rules::Coin;
    walletStatus.realMaxPrivacy = double(int64_t(AmountBig::get_Lo(beamStatus.maturingMP))) / Rules::Coin;

    walletStatus.currentHeight = [NSString stringWithUTF8String:to_string(status.stateID.m_Height).c_str()];
    walletStatus.currentStateHash = [NSString stringWithUTF8String:to_hex(status.stateID.m_Hash.m_pData, 15).c_str()];;
    walletStatus.currentStateFullHash = [NSString stringWithUTF8String:to_hex(status.stateID.m_Hash.m_pData, status.stateID.m_Hash.nBytes).c_str()];;


    auto assets = status.all;
    for (const auto& [key, value] : assets) {
        auto assetId = key;
        BOOL found = NO;
        for (int i=0;i<[[AssetsManager sharedManager]assets].count; i++) {
            BMAsset *asset = [[[AssetsManager sharedManager]assets] objectAtIndex:i];
            
            if (asset.assetId == assetId) {
                found = YES;
                
                asset.available =  AmountBig::get_Lo(value.available) + AmountBig::get_Lo(value.shielded);
                asset.receiving = AmountBig::get_Lo(value.receiving);
                asset.sending = AmountBig::get_Lo(value.sending);
                asset.shielded = AmountBig::get_Lo(value.shielded);
                asset.maxPrivacy = AmountBig::get_Lo(value.maturingMP);
                asset.maturing = AmountBig::get_Lo(value.maturing);

                asset.realAmount = (double(int64_t(AmountBig::get_Lo(value.available))) / Rules::Coin) + (double(int64_t(AmountBig::get_Lo(value.shielded))) / Rules::Coin);
                asset.realMaturing = double(int64_t(AmountBig::get_Lo(value.maturing))) / Rules::Coin;
                asset.realReceiving = (double(int64_t(AmountBig::get_Lo(value.receiving))) / Rules::Coin);
                asset.realSending = (double(int64_t(AmountBig::get_Lo(value.sending))) / Rules::Coin);
                asset.realShielded = double(int64_t(AmountBig::get_Lo(value.shielded))) / Rules::Coin;
                asset.realMaxPrivacy = double(int64_t(AmountBig::get_Lo(value.maturingMP))) / Rules::Coin;
                asset.realShielded = double(int64_t(AmountBig::get_Lo(value.shielded))) / Rules::Coin;

                [[[AssetsManager sharedManager]assets] replaceObjectAtIndex:i withObject:asset];
            }
        }
        
        if (!found) {
            BMAsset *asset = [[BMAsset alloc] init];
            asset.assetId = assetId;
            
            asset.available =  AmountBig::get_Lo(value.available) + AmountBig::get_Lo(value.shielded);
            asset.receiving = AmountBig::get_Lo(value.receiving);
            asset.sending = AmountBig::get_Lo(value.sending);
            asset.shielded = AmountBig::get_Lo(value.shielded);
            asset.maxPrivacy = AmountBig::get_Lo(value.maturingMP);
            asset.maturing = AmountBig::get_Lo(value.maturing);

            asset.realAmount = (double(int64_t(AmountBig::get_Lo(value.available))) / Rules::Coin) + (double(int64_t(AmountBig::get_Lo(value.shielded))) / Rules::Coin);
            asset.realMaturing = double(int64_t(AmountBig::get_Lo(value.maturing))) / Rules::Coin;
            asset.realReceiving = (double(int64_t(AmountBig::get_Lo(value.receiving))) / Rules::Coin);
            asset.realSending = (double(int64_t(AmountBig::get_Lo(value.sending))) / Rules::Coin);
            asset.realShielded = double(int64_t(AmountBig::get_Lo(value.shielded))) / Rules::Coin;
            asset.realMaxPrivacy = double(int64_t(AmountBig::get_Lo(value.maturingMP))) / Rules::Coin;
            asset.realShielded = double(int64_t(AmountBig::get_Lo(value.shielded))) / Rules::Coin;
            
            [[[AssetsManager sharedManager]assets] addObject:asset];
        }
    }
    
    [[AssetsManager sharedManager] changeAssets];
    
    for (int i=0;i<[[AssetsManager sharedManager]assets].count; i++) {
        BMAsset *asset = [[[AssetsManager sharedManager]assets] objectAtIndex:i];
        if (asset.name == nil || asset.name.isEmpty) {
            NSLog(@"GET ASSET %d",(uint)asset.assetId);
            if(asset.assetId == 0) {
                asset.assetId = 0;
                asset.nthUnitName = @"BEAM";
                asset.unitName = @"BEAM";
                asset.color = @"#00F6D2";
                asset.shortName = @"BEAM";
                asset.shortDesc = @"";
                asset.longDesc = @"";
                asset.site = @"";
                asset.paper = @"";
                [[[AssetsManager sharedManager]assets] replaceObjectAtIndex:i withObject:asset];
            }
            else {
                this->getAsync()->getAssetInfo((uint)asset.assetId);
            }
        }
    }
    
    [[AppModel sharedManager] setWalletStatus:walletStatus];

    NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
    for(id<WalletModelDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(onWalletStatusChange:)]) {
            [delegate onWalletStatusChange:walletStatus];
        }
    }
}

//GetAddressTo
//if (m_tx.m_sender)
//{
//    auto token = m_tx.getToken();
//    if (token.length() == 0) {
//        if(!m_tx.m_selfTx) {
//            return [NSString stringWithUTF8String:to_string(m_tx.m_peerId).c_str()];
//        }
//        return [NSString stringWithUTF8String:to_string(m_tx.m_myId).c_str()];
//    }
//    auto params = beam::wallet::ParseParameters(token);
//    if (auto peerIdentity = params->GetParameter<WalletID>(TxParameterID::PeerID); peerIdentity)
//    {
//        auto s = std::to_string(*peerIdentity);
//        return [NSString stringWithUTF8String:s.c_str()];
//    }
//    return [NSString stringWithUTF8String:token.c_str()];
//}
//return [NSString stringWithUTF8String:to_string(m_tx.m_myId).c_str()];

NSString* WalletModel::GetAddressTo(TxDescription transaction)
{
    if (transaction.m_sender)
    {
        auto token = transaction.getToken();
        if (token.length() == 0) {
            return [NSString stringWithUTF8String:to_string(transaction.m_peerAddr).c_str()];
        }

        return [NSString stringWithUTF8String:token.c_str()];
    }
    return [NSString stringWithUTF8String:to_string(transaction.m_myAddr).c_str()];
}

NSString* WalletModel::GetAddressFrom(TxDescription transaction)
{
    if (transaction.m_txType == wallet::TxType::PushTransaction && !transaction.m_sender)
    {
        return [NSString stringWithUTF8String:transaction.getSenderEndpoint().c_str()];
    }
    return transaction.m_sender ? [NSString stringWithUTF8String:to_string(transaction.m_myAddr).c_str()] : [NSString stringWithUTF8String:to_string(transaction.m_peerAddr).c_str()];
        
//    return [NSString stringWithUTF8String:transaction.getSenderEndpoint().c_str()];
    
//    if (transaction.m_txType == wallet::TxType::PushTransaction && !transaction.m_sender)
//    {
//        return [NSString stringWithUTF8String:transaction.getSenderIdentity().c_str()];
//    }
//
//    return transaction.m_sender ? [NSString stringWithUTF8String:to_string(transaction.m_myId).c_str()] : [NSString stringWithUTF8String:to_string(transaction.m_peerId).c_str()];
}

void WalletModel::onTxStatus(beam::wallet::ChangeAction action, const std::vector<beam::wallet::TxDescription>& items)
{
    NSMutableArray *transactions = [NSMutableArray new];
    
    auto currenCurrency = Currency::USD();
    
    BMCurrencyType currency = Settings.sharedManager.currency;
    
    if (currency == BMCurrencyETH) {
        currenCurrency = Currency::ETH();
    }
    else if (currency == BMCurrencyBTC) {
        currenCurrency = Currency::BTC();
    }
    
    for (const auto& item : items)
    {
        auto kernelId = to_hex(item.m_kernelID.m_pData, item.m_kernelID.nBytes);
        std::string comment(item.m_message.begin(), item.m_message.end());
              
        BMTransaction *transaction = [BMTransaction new];
        transaction.realAmount = double(int64_t(item.m_amount)) / Rules::Coin;
        transaction.createdTime = item.m_createTime;
        transaction.isIncome = (item.m_sender == false);
        transaction.status = [GetTransactionStatusString(item, transaction.isIncome) lowercaseString];
        transaction.enumStatus = (UInt64)item.m_status;
        transaction.enumType = (UInt64)item.m_txType;
        if (item.m_failureReason != TxFailureReason::Unknown) {
            transaction.failureReason = GetTransactionFailurString(item.m_failureReason);
        }
        else{
            transaction.failureReason = @"";
        }
        transaction.identity = [NSString stringWithUTF8String:item.getSender().c_str()];
        //[NSString stringWithUTF8String:item.getIdentity(item.m_sender).c_str()];
        transaction.ID = [NSString stringWithUTF8String:txIDToString(item.m_txId).c_str()];
        transaction.isSelf = item.m_selfTx;
        transaction.fee = double(int64_t(item.m_fee)) / Rules::Coin;
        transaction.realFee = int64_t(item.m_fee);
        transaction.kernelId = [NSString stringWithUTF8String:kernelId.c_str()];
        transaction.canCancel = item.canCancel();
        transaction.canResume = item.canResume();
        transaction.canDelete = item.canDelete();
        transaction.comment = [NSString stringWithUTF8String:comment.c_str()];
        transaction.senderIdentity = [NSString stringWithUTF8String:item.getSender().c_str()];
        transaction.receiverIdentity = [NSString stringWithUTF8String:item.getReceiver().c_str()];
        transaction.senderAddress = GetAddressFrom(item);
        transaction.receiverAddress = GetAddressTo(item);
        transaction.assetId = item.m_assetId;
        transaction.asset = [[AssetsManager sharedManager] getAsset:item.m_assetId];
        
        if (item.m_txType == wallet::TxType::Simple) {
            if (auto minConfirmations = item.GetParameter<uint32_t>(beam::wallet::TxParameterID::MinConfirmations))
            {
                transaction.minConfirmations = [NSString stringWithFormat:@"%d", *minConfirmations];
                transaction.minConfirmationsProgress = GetConfirmationProgress(item, *minConfirmations);
            }
        }
        
        if (item.m_txType == wallet::TxType::Contract) {
            transaction.isDapps = YES;
            
            bvm2::ContractInvokeData vData;
            Height h = item.m_minHeight;

            if (auto strdesc = item.GetParameter<std::string>(beam::wallet::TxParameterID::AppName))
            {
                transaction.appName = [NSString stringWithUTF8String:strdesc->c_str()];
            }
            
            if (auto strid = item.GetParameter<std::string>(beam::wallet::TxParameterID::AppID))
            {
                transaction.appID = [NSString stringWithUTF8String:strid->c_str()];
            }
            
            if(item.GetParameter(TxParameterID::ContractDataPacked, vData))
            {
                auto contractFee = vData.get_FullFee(h);
                auto contractSpend = vData.get_FullSpend();
                
                std::stringstream ss;
                ss << vData.m_vec[0].m_Cid.str();
                
                if (vData.m_vec.size() > 1)
                {
                    ss << " +" << vData.m_vec.size() - 1;
                }
                
                transaction.realFee = int64_t(contractFee);
                transaction.fee = double(int64_t(contractFee)) / Rules::Coin;
                transaction.contractCids = [NSString stringWithUTF8String:ss.str().c_str()];

                if (contractSpend.size() > 1) {
                    transaction.multiAssets = [NSMutableArray new];
                }
                
                for (const auto& info: contractSpend)
                {
                    auto amount = info.second;
                    if (info.first == beam::Asset::s_BeamID)
                    {
                        if (amount < 0)
                        {
                            amount += contractFee;
                        }
                    }
                    else {
                        transaction.assetId = info.first;
                        transaction.asset = [[AssetsManager sharedManager] getAsset:info.first];
                    }
                    
                    transaction.realAmount = transaction.realAmount + (double(int64_t(amount)) / Rules::Coin);
                    
                    if (contractSpend.size() > 1) {
                        BMAsset *asset = [[[AssetsManager sharedManager] getAsset:info.first] copy];
                        BOOL isIncome = amount < 0;
                        if(asset != nil) {
                            asset.realAmount = (double(int64_t(amount)) / Rules::Coin) * (-1);

                            if (!isIncome) {
                                asset.sending = int64_t(amount);
                                asset.realSending = (double(int64_t(amount)) / Rules::Coin);
                            } else {
                                asset.receiving = int64_t(amount);
                                asset.realReceiving = (double(int64_t(amount)) / Rules::Coin);
                            }
                            [transaction.multiAssets addObject:asset];
                        }
                    }
                }
                
                transaction.isIncome = transaction.realAmount <= 0;
                transaction.status = [GetTransactionStatusString(item, transaction.isIncome) lowercaseString];
                
                if (transaction.realAmount < 0) {
                    transaction.realAmount = transaction.realAmount * (-1.0);
                }
                
                if ([transaction isMultiAssets]) {
                    auto last = transaction.multiAssets.lastObject;
                    transaction.isIncome = last.realAmount > 0;
                    transaction.status = [GetTransactionStatusString(item, last.realAmount > 0) lowercaseString];
                }
            }
        }
        else if(item.m_txType == wallet::TxType::PushTransaction) {
            auto token = item.getToken();
            if (token.size() > 0) { //send
                auto p = wallet::ParseParameters(token);
                
                auto voucher = p->GetParameter<ShieldedTxo::Voucher>(TxParameterID::Voucher);
                transaction.isMaxPrivacy = !!voucher;
                
                auto vouchers = p->GetParameter<ShieldedVoucherList>(TxParameterID::ShieldedVoucherList);
                if (vouchers && !vouchers->empty())
                {
                    transaction.isShielded = true;
                }
                else
                {
                    auto gen = p->GetParameter<ShieldedTxo::PublicGen>(TxParameterID::PublicAddreessGen);
                    if (gen)
                    {
                        transaction.isPublicOffline = true;
                    }
                }
            }
            else { //recieved
                auto storedType = item.GetParameter<TxAddressType>(TxParameterID::AddressType);
                if (storedType)
                {
                    if(storedType == TxAddressType::PublicOffline) {
                        transaction.isPublicOffline = true;
                    }
                    else if(storedType == TxAddressType::MaxPrivacy) {
                        transaction.isMaxPrivacy = true;
                    }
                    else if(storedType == TxAddressType::Offline) {
                        transaction.isShielded = true;
                    }
                }
            }
        }
        
        auto rate = item.getExchangeRate(currenCurrency, transaction.assetId);
        transaction.realRate = int64_t(rate);

        transaction.token = [NSString stringWithUTF8String:item.getToken().c_str()];
        
        [transactions addObject:transaction];      
    }
    
    switch (action) {
        case ChangeAction::Added:
        {
            [[[AppModel sharedManager]transactions] addObjectsFromArray:transactions];
            break;
        }
        case ChangeAction::Removed:
        {
            NSMutableIndexSet *set = [NSMutableIndexSet new];
            
            for (int i=0;i<[[AppModel sharedManager]transactions].count; i++) {
                BMTransaction *tr_1 = [[[AppModel sharedManager]transactions] objectAtIndex:i];
                for (int j=0;j<transactions.count; j++) {
                    BMTransaction *tr_2 = [transactions objectAtIndex:j];
                    if([tr_1.ID isEqualToString:tr_2.ID])
                    {
                        [set addIndex:i];
                    }
                }
            }
            
            [[[AppModel sharedManager]transactions] removeObjectsAtIndexes:set];
            
            break;
        }
        case ChangeAction::Updated:
        {
            for (int i=0;i<[[AppModel sharedManager]transactions].count; i++) {
                BMTransaction *tr_1 = [[[AppModel sharedManager]transactions] objectAtIndex:i];
                for (int j=0;j<transactions.count; j++) {
                    BMTransaction *tr_2 = [transactions objectAtIndex:j];
                    if([tr_1.ID isEqualToString:tr_2.ID])
                    {
                        [[[AppModel sharedManager]transactions] replaceObjectAtIndex:i withObject:tr_2];
                    }
                }
            }
            break;
        }
        case ChangeAction::Reset:
        {
            [[[AppModel sharedManager]transactions] removeAllObjects];
            [[[AppModel sharedManager]transactions] addObjectsFromArray:transactions];
            break;
        }
        default:
            break;
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdTime"
                                                  ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray = [[[AppModel sharedManager]transactions] sortedArrayUsingDescriptors:sortDescriptors];
    
    [[[AppModel sharedManager]transactions] removeAllObjects];
    [[[AppModel sharedManager]transactions] addObjectsFromArray:sortedArray];

    NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
    
    for (int i=0; i<[AppModel sharedManager].preparedDeleteTransactions.count; i++) {
        NSString *id1 = [AppModel sharedManager].preparedDeleteTransactions[i].ID;
        
        for (int j=0; j<[[AppModel sharedManager]transactions].count; j++) {
            NSString *id2 = [AppModel sharedManager].transactions[j].ID;
            
            if ([id1 isEqualToString:id2]) {
                [set addIndex:j];
            }
        }
    }
    
    [[[AppModel sharedManager]transactions] removeObjectsAtIndexes:set];
    
          NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
      for(id<WalletModelDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(onReceivedTransactions:)]) {
            [delegate onReceivedTransactions:[[AppModel sharedManager]transactions]];
        }
    }
    
    [[AppModel sharedManager] changeTransactions];
        
    NSLog(@"onTxStatus");
}

void WalletModel::onSyncProgressUpdated(int done, int total)
{
    NSLog(@"onSyncProgressUpdated %d/%d",done, total);
    
    [AppModel sharedManager].isUpdating = (done != total);
    
    NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
    for(id<WalletModelDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(onSyncProgressUpdated: total:)]) {
            [delegate onSyncProgressUpdated:done total:total];
        }
    }    
}


void WalletModel::onNormalCoinsChanged(beam::wallet::ChangeAction action, const std::vector<beam::wallet::Coin>& utxos) {

    NSLog(@"onAllUtxoChanged");

    NSMutableArray *bmUtxos = [[NSMutableArray alloc] init];

    @autoreleasepool {
        for (const auto& coin : utxos)
        {
            BMAsset *asset = [[AssetsManager sharedManager] getAsset:coin.getAssetID()];
            
            BMUTXO *bmUTXO = [[BMUTXO alloc] init];
            bmUTXO.ID = coin.m_ID.m_Idx;
            bmUTXO.stringID = [NSString stringWithUTF8String:coin.toStringID().c_str()];
            bmUTXO.amount = coin.m_ID.m_Value;
            bmUTXO.realAmount = double(int64_t(coin.m_ID.m_Value)) / Rules::Coin;
            bmUTXO.status = (int)coin.m_status;
            bmUTXO.maturity = coin.m_maturity;
            bmUTXO.confirmHeight = coin.m_confirmHeight;
            bmUTXO.statusString = [GetUTXOStatusString(coin) lowercaseString];
            bmUTXO.typeString = GetUTXOTypeString(coin);
            bmUTXO.assetId = coin.getAssetID();
            bmUTXO.amountString = [[StringManager sharedManager] realAmountStringAsset:asset value:bmUTXO.realAmount];
            
            if (coin.m_createTxId)
            {
                string createdTxId = to_hex(coin.m_createTxId->data(), coin.m_createTxId->size());
                bmUTXO.createTxId = [NSString stringWithUTF8String:createdTxId.c_str()];
            }
            
            if (coin.m_spentTxId)
            {
                string spentTxId = to_hex(coin.m_spentTxId->data(), coin.m_spentTxId->size());
                bmUTXO.spentTxId = [NSString stringWithUTF8String:spentTxId.c_str()];
            }
            
            [bmUtxos addObject:bmUTXO];
        }
    }

    switch (action) {
           case ChangeAction::Added:
           {
               [[[AppModel sharedManager] utxos]addObjectsFromArray:bmUtxos];
               break;
           }
           case ChangeAction::Removed:
           {
               NSMutableIndexSet *set = [NSMutableIndexSet new];

               for (int i=0;i<[[AppModel sharedManager]utxos].count; i++) {
                   BMUTXO *tr_1 = [[[AppModel sharedManager]utxos] objectAtIndex:i];
                   for (int j=0;j<bmUtxos.count; j++) {
                       BMUTXO *tr_2 = [bmUtxos objectAtIndex:j];
                       if(tr_1.ID == tr_2.ID)
                       {
                           [set addIndex:i];
                       }
                   }
               }

               [[[AppModel sharedManager]utxos] removeObjectsAtIndexes:set];

               break;
           }
           case ChangeAction::Updated:
           {
               for (int i=0;i<[[AppModel sharedManager]utxos].count; i++) {
                   BMUTXO *tr_1 = [[[AppModel sharedManager]utxos] objectAtIndex:i];
                   for (int j=0;j<bmUtxos.count; j++) {
                       BMUTXO *tr_2 = [bmUtxos objectAtIndex:j];
                       if(tr_1.ID == tr_2.ID)
                       {
                           [[[AppModel sharedManager]utxos] replaceObjectAtIndex:i withObject:tr_2];
                       }
                   }
               }
               break;
           }
           case ChangeAction::Reset:
           {
               [[[AppModel sharedManager]utxos] removeAllObjects];
               [[AppModel sharedManager] setUtxos:bmUtxos];
               break;
           }
           default:
               break;
       }


    NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
    for(id<WalletModelDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(onReceivedUTXOs:)]) {
            [delegate onReceivedUTXOs:[[AppModel sharedManager]utxos]];
        }
    }
}

void WalletModel::onAddresses(bool own, const std::vector<beam::wallet::WalletAddress>& addrs)
{
    
    if (own)
    {
        NSLog(@"onAddresses OWN %lu", addrs.size());

        this->ownAddresses.clear();

        for (int i=0; i<addrs.size(); i++)
            this->ownAddresses.push_back(addrs[i]);
        
        NSMutableArray <BMAddress*> *addresses = [[NSMutableArray alloc] init];
        
        for (const auto& walletAddr : addrs)
        {
            NSString *categories = [NSString stringWithUTF8String:walletAddr.m_category.c_str()];
            if ([categories isEqualToString:@"0"]) {
                categories = @"";
            }
            
            BMAddress *address = [[BMAddress alloc] init];
            address.duration = walletAddr.m_duration;
            address.ownerId = walletAddr.m_OwnID;
            address.createTime = walletAddr.m_createTime;
            address.label = [NSString stringWithUTF8String:walletAddr.m_label.c_str()];
            if([address.label isEqualToString:@"Default"])
            {
                address.label = [@"default" localized];
            }
            address.walletId = [NSString stringWithUTF8String:to_string(walletAddr.m_BbsAddr).c_str()];
            address.identity = [NSString stringWithUTF8String:to_base58(walletAddr.m_Endpoint).c_str()];
            address.address = [NSString stringWithUTF8String:walletAddr.m_Token.c_str()];

            [addresses addObject:address];
        }
        
        NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
        
        for (int i=0; i<[AppModel sharedManager].preparedDeleteAddresses.count; i++) {
            NSString *id1 = [AppModel sharedManager].preparedDeleteAddresses[i].walletId;
                             
            for (int j=0; j<addresses.count; j++) {
                NSString *id2 = addresses[j].walletId;
                
                if ([id1 isEqualToString:id2]) {
                    [set addIndex:j];
                }
            }
        }
        
        [addresses removeObjectsAtIndexes:set];
        
        [[AppModel sharedManager] setWalletAddresses:addresses];

    NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
      for(id<WalletModelDelegate> delegate in delegates)
        {
            if ([delegate respondsToSelector:@selector(onWalletAddresses:)]) {
                [delegate onWalletAddresses:addresses];
            }
        }
    }
    else{
        NSLog(@"onAddresses Contacts %lu", addrs.size());

        this->contacts.clear();

        for (int i=0; i<addrs.size(); i++)
            this->contacts.push_back(addrs[i]);
        
        NSMutableArray <BMContact*>*contacts = [[NSMutableArray alloc] init];

        for (const auto& walletAddr : addrs)
        {
            BMAddress *address = [[BMAddress alloc] init];
            address.label = [NSString stringWithUTF8String:walletAddr.m_label.c_str()];
            address.walletId = [NSString stringWithUTF8String:to_string(walletAddr.m_BbsAddr).c_str()];
            address.identity = [NSString stringWithUTF8String:to_base58(walletAddr.m_Endpoint).c_str()];
            address.address = [NSString stringWithUTF8String:walletAddr.m_Token.c_str()];

            BOOL ignored = [[AppModel sharedManager] containsIgnoredContact:address.walletId];
            
            if((!address.address.isEmpty || !address.walletId.isEmpty) && !ignored) {
                BMContact *contact = [[BMContact alloc] init];
                contact.address = address;
                contact.name = address.label;
                
                [contacts addObject:contact];
            }
        }
        
        NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
        
        for (int i=0; i<[AppModel sharedManager].preparedDeleteAddresses.count; i++) {
            NSString *id1 = [AppModel sharedManager].preparedDeleteAddresses[i].walletId;
            
            for (int j=0; j<contacts.count; j++) {
                NSString *id2 = contacts[j].address.walletId;
                
                if ([id1 isEqualToString:id2]) {
                    [set addIndex:j];
                }
            }
        }
        
        [contacts removeObjectsAtIndexes:set];
        
//        for(int j = 0; j < [contacts count]; j++){
//            for(int k = j+1;k < [contacts count];k++){
//                BMContact *str1 = [contacts objectAtIndex:j];
//                BMContact *str2 = [contacts objectAtIndex:k];
//                if([str1.address.identity isEqualToString:str2.address.identity]) {
//                    [contacts removeObjectAtIndex:k];
//                }
//            }
//        }
        
        [[AppModel sharedManager] setContacts:contacts];
        
        NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
        for(id<WalletModelDelegate> delegate in delegates)
        {
            if ([delegate respondsToSelector:@selector(onContactsChange:)]) {
                [delegate onContactsChange:contacts];
            }
        }
    }
}

void WalletModel::onGeneratedNewAddress(const beam::wallet::WalletAddress& walletAddr)
{
    NSLog(@"onGeneratedNewAddress");

    [AppModel sharedManager].addressGeneratedID = [NSString stringWithUTF8String:to_base58(walletAddr.m_Endpoint).c_str()];

    getAsync()->saveAddress(walletAddr);

//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        [AppModel sharedManager].generatedNewAddressBlock(address, nil);
//    });
}

void WalletModel::onNewAddressFailed()
{
    [AppModel sharedManager].addressGeneratedID = @"";

    NSError *nativeError = [NSError errorWithDomain:AppErrorDomain
                                               code:1
                                           userInfo:@{ NSLocalizedDescriptionKey:@"Failed to genereate new address" }];
    
    if([AppModel sharedManager].generatedNewAddressBlock != nil) {
        [AppModel sharedManager].generatedNewAddressBlock(nil, nativeError);
    }
}

void WalletModel::onNodeConnectionChanged(bool isNodeConnected)
{
    NSLog(@"onNodeConnectionChanged %d",isNodeConnected);

    if (isNodeConnected) {
        auto trusted = this->isConnectionTrusted();
        NSLog(@"IS TRUSTED NODE OWN %d", trusted);
        
        auto own = [[AppModel sharedManager] checkIsOwnNode];
        NSLog(@"IS TRUSTED NODE %d", own);
    }

    
    if ([AppModel sharedManager].connectionTimer!=nil) {
        [[AppModel sharedManager].connectionTimer invalidate];
        [AppModel sharedManager].connectionTimer = nil;
    }
    
    if (![[AppModel sharedManager] isInternetAvailable] && isNodeConnected) {
        isNodeConnected = NO;
    }
    
    pre_connected_status = isNodeConnected;
    
    if (isNodeConnected)
    {
        [AppModel sharedManager].isNodeChanging = NO;
    }
    
    if (!isNodeConnected && AppModel.sharedManager.isConnecting)
    {
        [[AppModel sharedManager] setIsConnected:YES];

        [[AppModel sharedManager] startConnectionTimer:6];
    }
    else if (!isNodeConnected && [AppModel sharedManager].isNodeChanging)
    {
        [[AppModel sharedManager] startConnectionTimer:3];
    }
    else{
        [[AppModel sharedManager] setIsConnected:isNodeConnected];
        
        [[AppModel sharedManager] setIsConnecting:NO];
        
              NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
      for(id<WalletModelDelegate> delegate in delegates)
        {
            if ([delegate respondsToSelector:@selector(onNetwotkStatusChange:)]) {
                [delegate onNetwotkStatusChange:isNodeConnected];
            }
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if ([[AppModel sharedManager] isInternetAvailable] && !pre_connected_status) {
                [[AppModel sharedManager] reconnect];
            }
        }); 
    }
}

void WalletModel::onWalletError(beam::wallet::ErrorType error)
{
    if([Settings sharedManager].connectToRandomNode) {
        if(error == beam::wallet::ErrorType::ConnectionHostUnreach || error == beam::wallet::ErrorType::ConnectionRefused || error == beam::wallet::ErrorType::NodeProtocolIncompatible
           || error == beam::wallet::ErrorType::NodeProtocolBase)
        {
            BOOL isReconnect = [[AppModel sharedManager] reconnect];
            if (!isReconnect) {
                      NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
      for(id<WalletModelDelegate> delegate in delegates)
                {
                    if ([delegate respondsToSelector:@selector(onWalletError:)]) {
                        NSError *nativeError = [NSError errorWithDomain:AppErrorDomain
                                                                   code:NSUInteger(error)
                                                               userInfo:@{ NSLocalizedDescriptionKey:GetErrorString(error) }];
                        [delegate onWalletError:nativeError];
                    }
                }
            }
        }
    }
    else {
              NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
      for(id<WalletModelDelegate> delegate in delegates)
        {
            if ([delegate respondsToSelector:@selector(onWalletError:)]) {
                NSError *nativeError = [NSError errorWithDomain:AppErrorDomain
                                                           code:NSUInteger(error)
                                                       userInfo:@{ NSLocalizedDescriptionKey:GetErrorString(error) }];
                [delegate onWalletError:nativeError];
            }
        }
    }
}

//void WalletModel::onCoinsByTx(const std::vector<beam::Coin>& coins)
//{
//    
//}

void WalletModel::FailedToStartWallet()
{
    if([AppModel sharedManager].isLoggedin) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[AppModel sharedManager] restartWallet];
        });
    }
    else{
              NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
      for(id<WalletModelDelegate> delegate in delegates)
        {
            if ([delegate respondsToSelector:@selector(onWalletError:)]) {
                NSError *nativeError = [NSError errorWithDomain:AppErrorDomain
                                                           code:NSUInteger(12)
                                                       userInfo:@{ NSLocalizedDescriptionKey:@"Failed to start wallet" }];
                [delegate onWalletError:nativeError];
            }
        }
    }

    NSLog(@"FailedToStartWallet");
}

void WalletModel::onSendMoneyVerified()
{
          NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
      for(id<WalletModelDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(onSendMoneyVerified)]) {
            [delegate onSendMoneyVerified];
        }
    }
    
    NSLog(@"onSendMoneyVerified");
}

void WalletModel::onCantSendToExpired()
{
          NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
      for(id<WalletModelDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(onCantSendToExpired)]) {
            [delegate onCantSendToExpired];
        }
    }
    
    NSLog(@"onCantSendToExpired");
}

void WalletModel::onPaymentProofExported(const beam::wallet::TxID& txID, const beam::ByteBuffer& proof)
{
    NSLog(@"onPaymentProofExported");
    
    string str;
    str.resize(proof.size() * 2);
    str = to_hex(proof.data(), proof.size());
    
    BMPaymentProof *paymentProof = [[BMPaymentProof alloc] init];
    paymentProof.code = [NSString stringWithUTF8String:str.c_str()];
    paymentProof.txID = [NSString stringWithUTF8String:txIDToString(txID).c_str()];
    
    NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
    for(id<WalletModelDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(onReceivePaymentProof:)]) {
            [delegate onReceivePaymentProof:paymentProof];
        }
    }
}

void WalletModel::onCoinsByTx(const std::vector<beam::wallet::Coin>& coins){
    NSLog(@"onCoinsByTx");
}

void WalletModel::onAddressChecked(const std::string& addr, bool isValid){
    NSLog(@"onAddressChecked");
}

void WalletModel::onImportRecoveryProgress(uint64_t done, uint64_t total){
    recoveryProgress.OnProgress(done, total);
}

void WalletModel::onImportDataFromJson(bool isOk) {
    NSLog(@"onImportDataFromJson");
}

void WalletModel::onExportDataToJson(const std::string& data) {
    NSLog(@"onExportDataToJson");
}

void WalletModel::doFunction(const std::function<void()>& func)
{
    func();
}

void WalletModel::onPostFunctionToClientContext(MessageFunction&& func) {
    NSLog(@"onPostFunctionToClientContext");
        
    doFunction(func);
}

void WalletModel::onExportTxHistoryToCsv(const std::string& data) {
    NSString *csv = [NSString stringWithUTF8String:data.c_str()];
    
    NSTimeInterval date = [[NSDate date] timeIntervalSince1970];
    NSString *fileName = [NSString stringWithFormat:@"transactions_%d.csv",(int)date];
    NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    [csv writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    
    [AppModel sharedManager].getCSVBlock(csv, url);
}

void WalletModel::onAddressesChanged (beam::wallet::ChangeAction action, const std::vector <beam::wallet::WalletAddress > &items) {

    NSMutableArray *addresses = [NSMutableArray array];
    NSMutableArray *contacts = [NSMutableArray array];
    BOOL hasContacts = false;
    BOOL hasOwn = false;
    
    for (const auto& walletAddr : items)
    {
        if (walletAddr.isOwn()) {
            hasOwn = true;
            
            BMAddress *address = [[BMAddress alloc] init];
            address.duration = walletAddr.m_duration;
            address.ownerId = walletAddr.m_OwnID;
            address.createTime = walletAddr.m_createTime;
            address.label = [NSString stringWithUTF8String:walletAddr.m_label.c_str()];
            if([address.label isEqualToString:@"Default"])
            {
                address.label = [@"default" localized];
            }
            address.walletId = [NSString stringWithUTF8String:to_string(walletAddr.m_BbsAddr).c_str()];
            address.identity = [NSString stringWithUTF8String:to_base58(walletAddr.m_Endpoint).c_str()];
            address.address = [NSString stringWithUTF8String:walletAddr.m_Token.c_str()];
            
            [addresses addObject:address];
        }
        else {
            hasContacts = true;
            
            BMAddress *address = [[BMAddress alloc] init];
            address.label = [NSString stringWithUTF8String:walletAddr.m_label.c_str()];
            address.walletId = [NSString stringWithUTF8String:to_string(walletAddr.m_BbsAddr).c_str()];
            address.identity = [NSString stringWithUTF8String:to_base58(walletAddr.m_Endpoint).c_str()];
            address.address = [NSString stringWithUTF8String:walletAddr.m_Token.c_str()];
            
            BOOL ignored = [[AppModel sharedManager] containsIgnoredContact:address.walletId];
            
            if((!address.address.isEmpty || !address.walletId.isEmpty) && !ignored) {
                BMContact *contact = [[BMContact alloc] init];
                contact.address = address;
                contact.name = address.label;
                
                [contacts addObject:contact];
            }
        }
    }
    
    switch (action) {
        case ChangeAction::Added:
        {
            if(hasOwn) {
                [[[AppModel sharedManager]walletAddresses] addObjectsFromArray:addresses];
            }
            
            if(hasContacts) {
                [[[AppModel sharedManager]contacts] addObjectsFromArray:contacts];
            }
            
            break;
        }
        case ChangeAction::Removed:
        {
            NSMutableIndexSet *set = [NSMutableIndexSet new];
            
            if(hasOwn) {
                for (int i=0;i<[[AppModel sharedManager]walletAddresses].count; i++) {
                    BMAddress *add_1 = [[[AppModel sharedManager]walletAddresses] objectAtIndex:i];
                    for (int j=0;j<addresses.count; j++) {
                        BMAddress *add_2 = [addresses objectAtIndex:j];
                        if([add_1._id isEqualToString:add_2._id])
                        {
                            [set addIndex:i];
                        }
                    }
                }
                
                [[[AppModel sharedManager]walletAddresses] removeObjectsAtIndexes:set];
            }
            
            if(hasContacts) {
                set = [NSMutableIndexSet new];
                
                for (int i=0;i<[[AppModel sharedManager]contacts].count; i++) {
                    BMContact *add_1 = [[[AppModel sharedManager]contacts] objectAtIndex:i];
                    for (int j=0;j<contacts.count; j++) {
                        BMContact *add_2 = [contacts objectAtIndex:j];
                        if([add_1.address._id isEqualToString:add_2.address._id])
                        {
                            [set addIndex:i];
                        }
                    }
                }
                
                [[[AppModel sharedManager]contacts] removeObjectsAtIndexes:set];
            }
            
            break;
        }
        case ChangeAction::Updated:
        {
            if(hasOwn) {
                for (int i=0;i<[[AppModel sharedManager]walletAddresses].count; i++) {
                    BMAddress *add_1 = [[[AppModel sharedManager]walletAddresses] objectAtIndex:i];
                    for (int j=0;j<addresses.count; j++) {
                        BMAddress *add_2 = [addresses objectAtIndex:j];
                        if([add_1._id isEqualToString:add_2._id])
                        {
                            [[[AppModel sharedManager]walletAddresses] replaceObjectAtIndex:i withObject:add_2];
                        }
                    }
                }
            }
            
            if(hasContacts) {
                for (int i=0;i<[[AppModel sharedManager]contacts].count; i++) {
                    BMContact *add_1 = [[[AppModel sharedManager]contacts] objectAtIndex:i];
                    for (int j=0;j<contacts.count; j++) {
                        BMContact *add_2 = [contacts objectAtIndex:j];
                        if([add_1.address._id isEqualToString:add_2.address._id])
                        {
                            [[[AppModel sharedManager]contacts] replaceObjectAtIndex:i withObject:add_2];
                        }
                    }
                }
            }
            
            break;
        }
        case ChangeAction::Reset:
        {
      
            if (hasOwn) {
                [[[AppModel sharedManager]walletAddresses] removeAllObjects];
                [[[AppModel sharedManager]walletAddresses] addObjectsFromArray:addresses];
            }
            
            if (hasContacts) {
                [[[AppModel sharedManager]contacts] removeAllObjects];
                [[[AppModel sharedManager]contacts] addObjectsFromArray:contacts];
            }
            
            break;
        }
        default:
            break;
    }
    
    if(action == beam::wallet::ChangeAction::Added && items.size() == 1) {
        auto walletAddr = items[0];
        NSString *walletID = [NSString stringWithUTF8String:to_base58(walletAddr.m_Endpoint).c_str()];
        
        if([[AppModel sharedManager].addressGeneratedID isEqualToString:walletID]) {
            BMAddress *address = [[BMAddress alloc] init];
            address.duration = walletAddr.m_duration;
            address.ownerId = walletAddr.m_OwnID;
            address.createTime = walletAddr.m_createTime;
            address.label = [NSString stringWithUTF8String:walletAddr.m_label.c_str()];
            address.walletId = [NSString stringWithUTF8String:to_string(walletAddr.m_BbsAddr).c_str()];
            address.identity = [NSString stringWithUTF8String:to_base58(walletAddr.m_Endpoint).c_str()];
            address.address = [NSString stringWithUTF8String:walletAddr.m_Token.c_str()];
            [AppModel sharedManager].generatedNewAddressBlock(address, nil);
            [AppModel sharedManager].addressGeneratedID = @"";
        }
    }
    
    if (hasOwn) {
        NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
        for(id<WalletModelDelegate> delegate in delegates)
        {
            if ([delegate respondsToSelector:@selector(onWalletAddresses:)]) {
                [delegate onWalletAddresses:addresses];
            }
        }
    }
    
    if(hasContacts) {
        for(int j = 0; j < [[AppModel sharedManager].contacts count]; j++){
            for(int k = j+1;k < [[AppModel sharedManager].contacts count];k++){
                BMContact *str1 = [[AppModel sharedManager].contacts objectAtIndex:j];
                BMContact *str2 = [[AppModel sharedManager].contacts objectAtIndex:k];
                if([str1.address.identity isEqualToString:str2.address.identity]) {
                    [[AppModel sharedManager].contacts removeObjectAtIndex:k];
                }
            }
        }
        
        NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
        for(id<WalletModelDelegate> delegate in delegates)
        {
            if ([delegate respondsToSelector:@selector(onWalletAddresses:)]) {
                [delegate onContactsChange:contacts];
            }
        }
    }
}

void WalletModel::onExchangeRates(const std::vector<beam::wallet::ExchangeRate>& rates) {

    for (int i=0; i<rates.size(); i++) {
        
        auto rate = rates[i];
        NSString *name = [NSString stringWithUTF8String:rate.m_from.m_value.c_str()];

        BMCurrency *currency = [BMCurrency new];
        currency.value = rate.m_rate;
        currency.realValue = double(int64_t(rate.m_rate)) / Rules::Coin;
    
        if (rate.m_to == Currency::USD() && rate.m_from == Currency::BEAM()) {
            currency.type = BMCurrencyUSD;
            currency.maximumFractionDigits = 2;
            currency.code = @"USD";
            currency.name = @"BEAM";
        }
        else if (rate.m_to == Currency::BTC() && rate.m_from == Currency::BEAM()) {
            currency.type = BMCurrencyBTC;
            currency.maximumFractionDigits = 10;
            currency.code = @"BTC";
            currency.name = @"BEAM";
        }
        else if (rate.m_to == Currency::ETH() && rate.m_from == Currency::BEAM()) {
            currency.type = BMCurrencyETH;
            currency.maximumFractionDigits = 10;
            currency.code = @"ETH";
            currency.name = @"BEAM";
        }
        else if (rate.m_to == Currency::BTC() && [name containsString:@"asset"]) {
            currency.type = BMCurrencyBTC;
            currency.maximumFractionDigits = 10;
            currency.code = @"BTC";
            currency.name = name;
            currency.assetId = [[name stringByReplacingOccurrencesOfString:@"asset_" withString:@""] intValue];
        }
        else if (rate.m_to == Currency::USD() && [name containsString:@"asset"]) {
            currency.type = BMCurrencyUSD;
            currency.maximumFractionDigits = 2;
            currency.code = @"USD";
            currency.name = name;
            currency.assetId = [[name stringByReplacingOccurrencesOfString:@"asset_" withString:@""] intValue];
        }
        else if (rate.m_to == Currency::ETH() && [name containsString:@"asset"]) {
            currency.type = BMCurrencyETH;
            currency.maximumFractionDigits = 10;
            currency.code = @"ETH";
            currency.name = name;
            currency.assetId = [[name stringByReplacingOccurrencesOfString:@"asset_" withString:@""] intValue];
        }
        
        bool found = false;
        
        for (int j=0; j<[[[ExchangeManager sharedManager] currencies] count]; j++) {
            if([[[ExchangeManager sharedManager] currencies] objectAtIndex:j].type == currency.type
                && [[[[ExchangeManager sharedManager] currencies] objectAtIndex:j].name isEqualToString:currency.name]) {
                found = true;
                [[[ExchangeManager sharedManager] currencies] replaceObjectAtIndex:j withObject:currency];
                break;
            }
        }
        
        if (!found) {
            [[[ExchangeManager sharedManager] currencies] addObject:currency];
        }
    }
    
    if(rates.size() == 0) {
        [[[ExchangeManager sharedManager] currencies] removeAllObjects];
    }
        
    [[ExchangeManager sharedManager] changeCurrencies];
    
    NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
    for(id<WalletModelDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(onExchangeRatesChange)]) {
            [delegate onExchangeRatesChange];
        }
    }
    
    if([AppModel sharedManager].isConnected) {
              NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
      for(id<WalletModelDelegate> delegate in delegates)
        {
            if ([delegate respondsToSelector:@selector(onNetwotkStatusChange:)]) {
                [delegate onNetwotkStatusChange:YES];
            }
        }
    }
}


void WalletModel::onNotificationsChanged(beam::wallet::ChangeAction action, const std::vector<beam::wallet::Notification>& notifications) {
       
    if (action == beam::wallet::ChangeAction::Removed) {
        for (int i=0; i<notifications.size(); i++) {
            auto notification = notifications[i];
            NSString *nId = [NSString stringWithUTF8String:to_string(notification.m_ID).c_str()];
            NSLog(@"notification removed: %@", nId);
            
            NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
            for (int i=0; i<AppModel.sharedManager.notifications.count; i++) {
                if([AppModel.sharedManager.notifications[i].nId isEqualToString:nId]) {
                    [set addIndex:i];
                    break;
                }
            }
            [AppModel.sharedManager.notifications removeObjectsAtIndexes:set];
        }
    }
    else {
        for (int i=0; i<notifications.size(); i++) {
            BMNotification *bmNotification;
            
            auto notification = notifications[i];
            NSLog(@"notification received: %d", notification.m_type);
            
            NSString *nId = [NSString stringWithUTF8String:to_string(notification.m_ID).c_str()];
            
            if(notification.m_type == beam::wallet::Notification::Type::WalletImplUpdateAvailable && Settings.sharedManager.isNotificationWalletON) {
                beam::wallet::WalletImplVerInfo info;
                if (beam::wallet::fromByteBuffer(notification.m_content, info)) {
                    
                    int major = info.m_version.m_major;
                    int minor = info.m_version.m_minor;
                    int revision = (int)info.m_version.m_revision;
                    BOOL iOS = info.m_application == beam::wallet::VersionInfo::Application::IOSWallet;
                    
                    NSString *version = [NSString stringWithFormat:@"%d.%d", major, minor];
                   
                    NSLog(@"notification version: %@", version);
                    
                    NSDictionary *dictionary = [[NSBundle mainBundle] infoDictionary];
                    NSString *currentVersion = [dictionary objectForKey:@"CFBundleShortVersionString"];
                    NSString *currentBuild = [dictionary objectForKey:@"CFBundleVersion"];

                    int currentMajor = 0;
                    int currentMinor = 0;
                    int currentRevision = 0;
                    
                    NSArray *array = [currentVersion componentsSeparatedByString:@"."];
                    if([array count] == 3) {
                        currentMajor = [array[0] intValue];
                        currentMinor = [array[1] intValue];
                        currentRevision = [array[2] intValue];
                    }
                    else if([array count] == 2) {
                        currentMajor = [array[0] intValue];
                        currentMinor = [array[1] intValue];
                    }
                    else {
                        currentMajor = [currentVersion intValue];
                    }
                    
                    BOOL isUP = NO;
                    
                    if(currentMajor < major) {
                        isUP = YES;
                    }
                    else if(currentMajor == major && currentMinor < minor) {
                        isUP = YES;
                    }
                    else if(currentMajor == major && currentMinor == minor && currentRevision < revision) {
                        isUP = YES;
                    }
                    
                    if (iOS && isUP) {
                        bmNotification = [BMNotification new];
                        bmNotification.nId = nId;
                        bmNotification.type = VERSION;
                        bmNotification.pId = [NSString stringWithFormat:@"v%@.%d",version, revision];
                        bmNotification.isRead = notification.m_state == beam::wallet::Notification::State::Read;
                        bmNotification.createdTime = notification.m_createTime;
                    }
                }
            }
            else if(notification.m_type == beam::wallet::Notification::Type::AddressStatusChanged && Settings.sharedManager.isNotificationAddressON) {
                beam::wallet::WalletAddress address;
                if (beam::wallet::fromByteBuffer(notification.m_content, address))  {
                    NSString *pid = [NSString stringWithUTF8String:to_base58(address.m_Endpoint).c_str()];
                    if(address.isExpired() && ![[AppModel sharedManager].deletedNotifications valueForKey:pid]) {
                        bmNotification = [BMNotification new];
                        bmNotification.nId = nId;
                        bmNotification.pId = pid;
                        bmNotification.type = ADDRESS;
                        bmNotification.isRead = notification.m_state == beam::wallet::Notification::State::Read;
                        bmNotification.createdTime = notification.m_createTime;
                    }
                    else {
                        [[[AppModel sharedManager] deletedNotifications] removeObjectForKey:pid];
                        [[AppModel sharedManager] deleteNotification:nId];
                        return;
                    }
                    NSLog(@"notification address: %@", bmNotification.pId);
                }
            }
            else if((notification.m_type == beam::wallet::Notification::Type::TransactionFailed
                     || notification.m_type == beam::wallet::Notification::Type::TransactionCompleted) && Settings.sharedManager.isNotificationTransactionON) {
                TxToken token;
                Deserializer d;
                d.reset(notification.m_content);
                d& token;
                beam::wallet::TxParameters transaction = token.UnpackParameters();
                auto txStatus = transaction.GetParameter<wallet::TxStatus>(TxParameterID::Status);
                    
                std::string tx = to_hex(transaction.GetTxID()->data(), transaction.GetTxID()->size());
                NSString *txId = [NSString stringWithUTF8String:tx.c_str()];
                
                BMTransaction *bmTransaction = [[AppModel sharedManager] transactionById:txId];
                
                if(bmTransaction == nil) {
                    NSLog(@"transaction not found");
                    [NSThread sleepForTimeInterval:1.5f];
                }
                else {
                    if (bmTransaction.enumStatus != BMTransactionStatusFailed && txStatus == TxStatus::Failed) {
                        [[AppModel sharedManager] setTransactionStatusToFailed:txId];
                    }
                }
                
                bmNotification = [BMNotification new];
                bmNotification.nId = nId;
                bmNotification.pId = txId;
                bmNotification.type = TRANSACTION;
                bmNotification.isRead = notification.m_state == beam::wallet::Notification::State::Read;
                bmNotification.createdTime = notification.m_createTime;
                NSLog(@"notification transaction: %@", bmNotification.pId);
            }
            else if(notification.m_type == beam::wallet::Notification::Type::BeamNews && Settings.sharedManager.isNotificationNewsON) {
                bmNotification = [BMNotification new];
                bmNotification.nId = nId;
                bmNotification.type = NEWS;
                bmNotification.isRead = false;
                bmNotification.createdTime = notification.m_createTime;
                
                NSLog(@"notification news: %@", bmNotification.nId);
            }
            
            if(bmNotification != nil) {
                int index = -1;
                for (int i=0; i<AppModel.sharedManager.notifications.count; i++) {
                    if([AppModel.sharedManager.notifications[i].nId isEqualToString:nId]) {
                        index = i;
                        [AppModel.sharedManager.notifications replaceObjectAtIndex:i withObject:bmNotification];
                        break;
                    }
                }
                if(index == -1) {
                    [AppModel.sharedManager.notifications addObject:bmNotification];
                }
            }
        }
    }
        
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdTime"
                                                                   ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray = [[[AppModel sharedManager] notifications] sortedArrayUsingDescriptors:sortDescriptors];
    
    [[[AppModel sharedManager] notifications] removeAllObjects];
    [[[AppModel sharedManager] notifications] addObjectsFromArray:sortedArray];
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults]objectForKey:@"sendedNotificationsKey"]];
    
    for (int i=0; i < [[AppModel sharedManager] notifications].count; i++) {
        BOOL isSend = [array containsObject: [[[AppModel sharedManager] notifications]objectAtIndex:i].nId];
        [[[AppModel sharedManager] notifications]objectAtIndex:i].isSended = isSend;
    }
    
    NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
    for(id<WalletModelDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(onNotificationsChanged)]) {
            [delegate onNotificationsChanged];
        }
    }
    
    [[AppModel sharedManager] changeNotifications];
}

void WalletModel::onGetAddress(const beam::wallet::WalletID& wid, const boost::optional<beam::wallet::WalletAddress>& address, size_t offlinePayments) {
    
    NSLog(@"onGetAddress: %d", (int)offlinePayments);
    
    NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
    for(id<WalletModelDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(onMaxPrivacyTokensLeft:)]) {
            [delegate onMaxPrivacyTokensLeft:(int)offlinePayments];
        }
    }
}

void WalletModel::onShieldedCoinChanged(beam::wallet::ChangeAction action, const std::vector<beam::wallet::ShieldedCoin>& items) {
    NSLog(@"onShieldedCoinChanged");
    
    NSMutableArray *bmUtxos = [[NSMutableArray alloc] init];
            
    
    @autoreleasepool {
        for (const auto& coin : items)
        {
            shieldedCoins[coin.m_TxoID] = coin;

            BMUTXO *bmUTXO = [[BMUTXO alloc] init];
            bmUTXO.isShilded = YES;
            bmUTXO.txoID = coin.m_TxoID;
            bmUTXO.ID = coin.m_spentHeight;
            bmUTXO.user = 0; //coin.m_CoinID.m_User;
            bmUTXO.assetId = coin.getAssetID();
            bmUTXO.stringID = [NSString stringWithFormat:@"%llu", bmUTXO.ID];
            bmUTXO.amount = coin.m_CoinID.m_Value;
            bmUTXO.realAmount = double(int64_t(coin.m_CoinID.m_Value)) / Rules::Coin;
            bmUTXO.status = (int)coin.m_Status;
            switch (coin.m_Status)
            {
                case ShieldedCoin::Available:
                    bmUTXO.status = BMUTXOAvailable;
                    bmUTXO.statusString = [[@"available" localized] lowercaseString];
                    break;
                case ShieldedCoin::Maturing:
                    bmUTXO.status = BMUTXOMaturing;
                    bmUTXO.statusString = [[@"maturing" localized] lowercaseString];
                    break;
                case ShieldedCoin::Unavailable:
                    bmUTXO.status = BMUTXOUnavailable;
                    bmUTXO.statusString = [[@"unavailable" localized] lowercaseString];
                    break;
                case ShieldedCoin::Outgoing:
                    bmUTXO.status = BMUTXOOutgoing;
                    bmUTXO.statusString = [[@"in_progress_out" localized] lowercaseString];
                    break;
                case ShieldedCoin::Incoming:
                    bmUTXO.status = BMUTXOIncoming;
                    bmUTXO.statusString = [[@"in_progress_in" localized] lowercaseString];
                    break;
                case ShieldedCoin::Spent:
                    bmUTXO.status = BMUTXOSpent;
                    bmUTXO.statusString = [[@"spent" localized] lowercaseString];
                    break;
                default:
                    break;
            }
            bmUTXO.maturity = coin.m_confirmHeight;
            bmUTXO.confirmHeight = coin.m_confirmHeight;
            bmUTXO.typeString = @"Shielded";

            if (coin.m_createTxId)
            {
                string createdTxId = to_hex(coin.m_createTxId->data(), coin.m_createTxId->size());
                bmUTXO.createTxId = [NSString stringWithUTF8String:createdTxId.c_str()];
            }
            
            if (coin.m_spentTxId)
            {
                string spentTxId = to_hex(coin.m_spentTxId->data(), coin.m_spentTxId->size());
                bmUTXO.spentTxId = [NSString stringWithUTF8String:spentTxId.c_str()];
            }
        
            [bmUtxos addObject:bmUTXO];
        }
    }
    
    switch (action) {
        case ChangeAction::Added:
        {
            [[[AppModel sharedManager] shildedUtxos]addObjectsFromArray:bmUtxos];
            break;
        }
        case ChangeAction::Removed:
        {
            NSMutableIndexSet *set = [NSMutableIndexSet new];
            
            for (int i=0;i<[[AppModel sharedManager]shildedUtxos].count; i++) {
                BMUTXO *tr_1 = [[[AppModel sharedManager]shildedUtxos] objectAtIndex:i];
                for (int j=0;j<bmUtxos.count; j++) {
                    BMUTXO *tr_2 = [bmUtxos objectAtIndex:j];
                    if(tr_1.ID == tr_2.ID)
                    {
                        [set addIndex:i];
                    }
                }
            }
            
            [[[AppModel sharedManager]shildedUtxos] removeObjectsAtIndexes:set];
            
            break;
        }
        case ChangeAction::Updated:
        {
            for (int i=0;i<[[AppModel sharedManager]shildedUtxos].count; i++) {
                BMUTXO *tr_1 = [[[AppModel sharedManager]shildedUtxos] objectAtIndex:i];
                for (int j=0;j<bmUtxos.count; j++) {
                    BMUTXO *tr_2 = [bmUtxos objectAtIndex:j];
                    if(tr_1.ID == tr_2.ID)
                    {
                        [[[AppModel sharedManager]shildedUtxos] replaceObjectAtIndex:i withObject:tr_2];
                    }
                }
            }
            break;
        }
        case ChangeAction::Reset:
        {
            [[[AppModel sharedManager] shildedUtxos] removeAllObjects];
            [[[AppModel sharedManager] shildedUtxos]addObjectsFromArray:bmUtxos];
            break;
        }
        default:
            break;
    }
    
        
    NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
    for(id<WalletModelDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(onReceivedUTXOs:)]) {
            [delegate onReceivedUTXOs:[[AppModel sharedManager]utxos]];
        }
    }
}

void WalletModel::onChangeCalculated(beam::Amount changeAsset, beam::Amount changeBeam, beam::Asset::ID assetId)
{
    NSLog(@"onChangeCalculated");
}

void WalletModel::onCoinsSelected(const CoinsSelectionInfo& selectionRes)
{
    NSLog(@"onCoinsSelectionCalculated");
    
    auto change = double(int64_t(selectionRes.m_changeAsset)) / Rules::Coin;
    double real = double(int64_t(AmountBig::get_Lo(selectionRes.m_selectedSumAsset))) / Rules::Coin;

    [AppModel sharedManager].feecalculatedBlock(selectionRes.m_minimalExplicitFee, change, 0, real);
}

void WalletModel::onPublicAddress(const std::string& publicAddr)
{
    NSString * address = [NSString stringWithUTF8String:publicAddr.c_str()];
    [AppModel sharedManager].getPublicAddressBlock(address);
}


void WalletModel::onAssetInfo(Asset::ID assetId, const WalletAsset& asset) {
    NSLog(@"onAssetInfo :%d", assetId);
    
    auto info = WalletAssetMeta(asset);

    NSString *name = [NSString stringWithUTF8String:info.GetName().c_str()];
    NSString *nthName = [NSString stringWithUTF8String:info.GetNthUnitName().c_str()];
    NSString *unitName = [NSString stringWithUTF8String:info.GetUnitName().c_str()];
    NSString *shortName = [NSString stringWithUTF8String:info.GetShortName().c_str()];
    NSString *shortDesc = [NSString stringWithUTF8String:info.GetShortDesc().c_str()];
    NSString *longDesc = [NSString stringWithUTF8String:info.GetLongDesc().c_str()];
    NSString *site = [NSString stringWithUTF8String:info.GetSiteUrl().c_str()];
    NSString *paper = [NSString stringWithUTF8String:info.GetPaperUrl().c_str()];
    NSString *color = [NSString stringWithUTF8String:info.GetColor().c_str()];
    if(color.isEmpty) {
        color = [[AssetsManager sharedManager] getAssetColor:assetId];
    }
    
    NSUInteger index = [[[AssetsManager sharedManager]assets] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        BMAsset *myObject = (BMAsset *)obj;
        return myObject.assetId == UInt64(assetId);
    }];
    
    BMAsset* bmAsset;
    if (index == NSNotFound) {
        bmAsset = [[BMAsset alloc] init];
    }
    else {
        bmAsset = [[[AssetsManager sharedManager]assets] objectAtIndex:index];
    }
    
    bmAsset.assetId = UInt64(assetId);
    bmAsset.nthUnitName = nthName;
    bmAsset.unitName = unitName;
    bmAsset.shortName = shortName;
    bmAsset.shortDesc = shortDesc;
    bmAsset.longDesc = longDesc;
    bmAsset.site = site;
    bmAsset.color = color;
    bmAsset.paper = paper;
    if(bmAsset.assetId == 12 && [Settings.sharedManager target] == Testnet) {
        bmAsset.color = @"#977dff";
    }
    else if(bmAsset.assetId == 3 && [Settings.sharedManager target] == Masternet) {
        bmAsset.color = @"#977dff";
    }
    else if(bmAsset.assetId == 7 && [Settings.sharedManager target] == Mainnet) {
        bmAsset.color = @"#977dff";
    }
    
    if(index == NSNotFound) {
        [[[AssetsManager sharedManager]assets] addObject:bmAsset];
    }
    else {
        [[[AssetsManager sharedManager]assets] replaceObjectAtIndex:index withObject:bmAsset];

    }
    
    [[AssetsManager sharedManager] changeAssets];

    NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
    for(id<WalletModelDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(onAssetInfoChange)]) {
            [delegate onAssetInfoChange];
        }
    }
}

NSString* WalletModel::GetErrorString(beam::wallet::ErrorType type)
{
    switch (type)
    {
        case wallet::ErrorType::NodeProtocolBase:
            return @"Node protocol error!";
        case wallet::ErrorType::NodeProtocolIncompatible:
            return @"You are trying to connect to incompatible peer.";
        case wallet::ErrorType::ConnectionBase:
            return @"Connection error.";
        case wallet::ErrorType::HostResolvedError:
            return [NSString stringWithFormat:@"Unable to resolve node address: %@", [Settings sharedManager].nodeAddress] ;
        case wallet::ErrorType::ConnectionTimedOut:
            return @"Connection timed out.";
        case wallet::ErrorType::ConnectionRefused:
            return @"Cannot connect to node";
        case wallet::ErrorType::ConnectionHostUnreach:
            return @"Node is unreachable";
        case wallet::ErrorType::ConnectionAddrInUse:
            return @"The port is already in use. Check if a wallet is already running on this machine or change the port settings.";
        case wallet::ErrorType::TimeOutOfSync:
            return @"System time not synchronized.";
        default:
            return @"Unexpected error!";
    }
}

NSString* WalletModel::GetConfirmationProgress(TxDescription transaction, uint32_t minConfirmations)
{
    if (minConfirmations)
    {
        auto currHeight = this->getCurrentHeight();
        if (currHeight && minConfirmations)
        {
            if (auto proofHeight = transaction.GetParameter<Height>(wallet::TxParameterID::KernelProofHeight); proofHeight)
            {
                std::stringstream ss;
                auto blocksAfter = (currHeight - *proofHeight);
                ss << (blocksAfter > minConfirmations ? minConfirmations : blocksAfter) << "/" << minConfirmations;
                return [NSString stringWithUTF8String:ss.str().c_str()];
            }
            else
            {
                std::stringstream ss;
                ss << 0 << "/" << minConfirmations;
                return [NSString stringWithUTF8String:ss.str().c_str()];
            }
        }
    }
    return @"unknown";
}

NSString* WalletModel::GetTransactionStatusString(TxDescription transaction, BOOL income)
{
    bool isIncome = income;
    
    switch (transaction.m_status)
    {
        case TxStatus::Pending:
        {
            if (transaction.m_selfTx)
            {
                return [[@"sending_to_own" localized] lowercaseString];
            }
            return [[@"pending" localized] lowercaseString];
        }
        case TxStatus::InProgress:{
            if (transaction.m_selfTx)   {
                return [[@"sending_to_own" localized] lowercaseString];
            }
            return isIncome ? [[@"waiting_for_sender" localized]lowercaseString] : [[@"waiting_for_receiver" localized]lowercaseString];
        }
        case TxStatus::Confirming:{
            return [[@"confirming" localized] lowercaseString];
        }
        case TxStatus::Registering:{
            if (transaction.m_selfTx)  {
                return [[@"sending_to_own" localized] lowercaseString];
            }
            return isIncome ? [[@"in_progress" localized]lowercaseString] : [[@"in_progress" localized] lowercaseString];
        }
        case TxStatus::Completed:
        {
            if (transaction.m_selfTx)  {
                return [[@"sent_to_own" localized] lowercaseString];
            }
            return isIncome ? [[@"received" localized] lowercaseString] : [[@"sent" localized] lowercaseString];
        }
        case TxStatus::Canceled:
            return [[@"canceled" localized] lowercaseString];
        case TxStatus::Failed:
            {
                if (transaction.m_failureReason == TxFailureReason::TransactionExpired)
                {
                    return [[@"expired" localized] lowercaseString];
                }
            }
            return [[@"failed" localized] lowercaseString];
        default:
            break;
    }
    
    return [[@"unknown" localized] lowercaseString];
}

NSString* WalletModel::GetTransactionFailurString(TxFailureReason reason)
{
    NSArray *reasons = @[[[@"tx_failure_undefined" localized] lowercaseString],
                         [[@"tx_failure_cancelled" localized] lowercaseString],
                         [[@"tx_failure_receiver_signature_invalid" localized] lowercaseString],
                         [[@"tx_failure_not_registered_in_blockchain" localized] lowercaseString],
                         [[@"tx_failure_not_valid" localized] lowercaseString],
                         [[@"tx_failure_kernel_invalid" localized] lowercaseString],
                         [[@"tx_failure_parameters_not_sended" localized] lowercaseString],
                         [[@"tx_failure_no_inputs" localized] lowercaseString],
                         [[@"tx_failure_addr_expired" localized] lowercaseString],
                         [[@"tx_failure_parameters_not_readed" localized] lowercaseString],
                         [[@"tx_failure_time_out" localized] lowercaseString],
                         [[@"tx_failure_not_signed_by_receiver" localized] lowercaseString],
                         [[@"tx_failure_max_height_to_high" localized] lowercaseString],
                         [[@"tx_failure_invalid_state" localized] lowercaseString],
                         [[@"tx_failure_subtx_failed" localized] lowercaseString],
                         [[@"tx_failure_invalid_contract_amount" localized] lowercaseString],
                         [[@"tx_failure_invalid_sidechain_contract" localized] lowercaseString],
                         [[@"tx_failure_sidechain_internal_error" localized] lowercaseString],
                         [[@"tx_failure_sidechain_network_error" localized] lowercaseString],
                         [[@"tx_failure_invalid_sidechain_response_format" localized] lowercaseString],
                         [[@"tx_failure_invalid_side_chain_credentials" localized] lowercaseString],
                         [[@"tx_failure_not_enough_time_btc_lock" localized] lowercaseString],
                         [[@"tx_failure_create_multisig" localized] lowercaseString],
                         [[@"tx_failure_fee_too_small" localized] lowercaseString],
                         [[@"tx_failure_fee_too_large" localized] lowercaseString],
                         [[@"tx_failure_kernel_min_height" localized] lowercaseString],
                         [[@"tx_failure_loopback" localized] lowercaseString],
                         [[@"tx_failure_key_keeper_no_initialized" localized] lowercaseString],
                         [[@"tx_failure_invalid_asset_id" localized] lowercaseString],
                         [[@"tx_failure_asset_invalid_info" localized] lowercaseString],
                         [[@"tx_failure_asset_invalid_metadata" localized] lowercaseString],
                         [[@"tx_failure_asset_invalid_id" localized] lowercaseString],
                         [[@"tx_failure_asset_confirmation" localized] lowercaseString],
                         [[@"tx_failure_asset_in_use" localized] lowercaseString],
                         [[@"tx_failure_asset_locked" localized] lowercaseString],
                         [[@"tx_failure_asset_small_fee" localized] lowercaseString],
                         [[@"tx_failure_invalid_asset_amount" localized] lowercaseString],
                         [[@"tx_failure_invalid_data_for_payment_proof" localized] lowercaseString],
                         [[@"tx_failure_there_is_no_master_key" localized] lowercaseString],
                         [[@"tx_failure_keeper_malfunctioned" localized] lowercaseString],
                         [[@"tx_failure_aborted_by_user" localized] lowercaseString],
                         [[@"tx_failure_asset_exists" localized] lowercaseString],
                         [[@"tx_failure_asset_invalid_owner_id" localized] lowercaseString],
                         [[@"tx_failure_assets_disabled" localized] lowercaseString],
                         [[@"tx_failure_no_vouchers" localized] lowercaseString],
                         [[@"tx_failure_assets_fork2" localized] lowercaseString],
                         [[@"tx_failure_out_of_slots" localized] lowercaseString],
                         [[@"tx_failure_shielded_coin_fee" localized] lowercaseString],
                         [[@"tx_failure_assets_disabled_receiver" localized] lowercaseString],
                         [[@"tx_failure_assets_disabled_blockchain" localized] lowercaseString],
                         [[@"tx_failure_identity_required" localized] lowercaseString],
                         [[@"tx_failure_cannot_get_vouchers" localized] lowercaseString]];
    
    if(reason >= reasons.count) {
        return @"";
    }

    return reasons[reason];
}

NSString* WalletModel::GetShildedUTXOStatusString(beam::wallet::ShieldedCoin coin)
{
    switch (coin.m_Status)
    {
        case ShieldedCoin::Available:
            return [[@"available" localized] lowercaseString];
        case ShieldedCoin::Maturing:
            return [[@"maturing" localized] lowercaseString];
        case ShieldedCoin::Unavailable:
            return [[@"unavailable" localized] lowercaseString];
        case ShieldedCoin::Outgoing:
            return [[@"in_progress_out" localized] lowercaseString];
        case ShieldedCoin::Incoming: {
            return [[@"in_progress_in" localized] lowercaseString];
        }
            
        case ShieldedCoin::Spent:
            return [[@"spent" localized] lowercaseString];
        default:
            break;
    }
    
    return @"unknown";
}

NSString* WalletModel::GetShildedUTXOTypeString(beam::wallet::ShieldedCoin coin) {
    return @"unknown";
}

NSString* WalletModel::GetUTXOStatusString(Coin coin)
{
    switch (coin.m_status)
    {
        case Coin::Available:
            return [[@"available" localized] lowercaseString];
        case Coin::Maturing:
            return [[@"maturing" localized] lowercaseString];
        case Coin::Unavailable:
            return [[@"unavailable" localized] lowercaseString];
        case Coin::Outgoing:
            return [[@"in_progress_out" localized] lowercaseString];
        case Coin::Incoming: {
            if (coin.m_ID.m_Type == Key::Type::Change)
            {
                return [[@"in_progress_change" localized] lowercaseString];
            }
            return [[@"in_progress_in" localized] lowercaseString];
        }
            
        case Coin::Spent:
            return [[@"spent" localized] lowercaseString];
        default:
            break;
    }
    
    return @"unknown";
}

NSString* WalletModel::GetUTXOTypeString(beam::wallet::Coin coin) {
    switch (coin.m_ID.m_Type)
    {
        case Key::Type::Asset:
            return [[@"Asset" localized] lowercaseString];
        case Key::Type::Decoy:
            return [[@"Decoy" localized] lowercaseString];
        case Key::Type::Bbs:
            return [[@"BBS" localized] lowercaseString];
        case Key::Type::ChildKey:
            return [[@"ChildKey" localized] lowercaseString];
        case Key::Type::Comission:
            return [[@"transaction_fee" localized] lowercaseString];
        case Key::Type::Coinbase:
            return [[@"coinbase" localized] lowercaseString];
        case Key::Type::Regular:
            return [[@"regular" localized] lowercaseString];
        case Key::Type::Change:
            return [[@"utxo_type_change" localized] lowercaseString];
            
        case Key::Type::Treasury: {
            return [[@"treasury" localized] lowercaseString];
        }
    }
    return @"unknown";
}
