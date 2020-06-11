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

#import "StringStd.h"

using namespace beam;
using namespace beam::io;
using namespace beam::wallet;
using namespace std;

//using namespace beam;
//using namespace beam::io;
//using namespace std;

NSString *const AppErrorDomain = @"beam.mw";
NSTimer *timer;

WalletModel::WalletModel(IWalletDB::Ptr walletDB, const std::string& nodeAddr, beam::io::Reactor::Ptr reactor)
: WalletClient(walletDB, nodeAddr, reactor)
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

    BMWalletStatus *walletStatus = [[BMWalletStatus alloc] init];
    walletStatus.available = status.available;
    walletStatus.receiving = status.receiving;
    walletStatus.maturing = status.maturing;
    walletStatus.sending = status.sending;
    walletStatus.realAmount = double(int64_t(status.available)) / Rules::Coin;
    walletStatus.realMaturing = double(int64_t(status.maturing)) / Rules::Coin;
    walletStatus.realSending = double(int64_t(status.sending)) / Rules::Coin;
    walletStatus.realReceiving = double(int64_t(status.receiving)) / Rules::Coin;
    walletStatus.currentHeight = [NSString stringWithUTF8String:to_string(status.stateID.m_Height).c_str()];
    walletStatus.currentStateHash = [NSString stringWithUTF8String:to_hex(status.stateID.m_Hash.m_pData, 15).c_str()];;
    walletStatus.currentStateFullHash = [NSString stringWithUTF8String:to_hex(status.stateID.m_Hash.m_pData, status.stateID.m_Hash.nBytes).c_str()];;
    
    [[AppModel sharedManager] setWalletStatus:walletStatus];

    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onWalletStatusChange:)]) {
            [delegate onWalletStatusChange:walletStatus];
        }
    }
}

void WalletModel::onTxStatus(beam::wallet::ChangeAction action, const std::vector<beam::wallet::TxDescription>& items)
{
    NSMutableArray *transactions = [NSMutableArray new];
    
    for (const auto& item : items)
    {
        auto kernelId = to_hex(item.m_kernelID.m_pData, item.m_kernelID.nBytes);
        std::string comment(item.m_message.begin(), item.m_message.end());
        
        BMTransaction *transaction = [BMTransaction new];
        transaction.realAmount = double(int64_t(item.m_amount)) / Rules::Coin;
        transaction.createdTime = item.m_createTime;
        transaction.isIncome = (item.m_sender == false);
        transaction.status = [GetTransactionStatusString(item) lowercaseString];
        transaction.enumStatus = (UInt64)item.m_status;
        if (item.m_failureReason != TxFailureReason::Unknown)
        {
            transaction.failureReason = GetTransactionFailurString(item.m_failureReason);
        }
        else{
            transaction.failureReason = @"";
        }
        transaction.ID = [NSString stringWithUTF8String:txIDToString(item.m_txId).c_str()];
        transaction.isSelf = item.m_selfTx;
        transaction.fee = double(int64_t(item.m_fee)) / Rules::Coin;
        transaction.realFee = int64_t(item.m_fee);
        transaction.kernelId = [NSString stringWithUTF8String:kernelId.c_str()];
        transaction.canCancel = item.canCancel();
        transaction.canResume = item.canResume();
        transaction.canDelete = item.canDelete();
        transaction.comment = [NSString stringWithUTF8String:comment.c_str()];
        
        if (item.m_sender) {
            transaction.senderAddress = [NSString stringWithUTF8String:to_string(item.m_myId).c_str()];
        }
        else{
            transaction.senderAddress = [NSString stringWithUTF8String:to_string(item.m_peerId).c_str()];
        }
        
        if (item.m_sender) {
            transaction.receiverAddress = [NSString stringWithUTF8String:to_string(item.m_peerId).c_str()];
        }
        else{
            transaction.receiverAddress = [NSString stringWithUTF8String:to_string(item.m_myId).c_str()];
        }
        
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
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onReceivedTransactions:)]) {
            [delegate onReceivedTransactions:[[AppModel sharedManager]transactions]];
        }
    }
        
    NSLog(@"onTxStatus");
}

void WalletModel::onSyncProgressUpdated(int done, int total)
{
    NSLog(@"onSyncProgressUpdated %d/%d",done, total);

    [AppModel sharedManager].isUpdating = (done != total);

    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onSyncProgressUpdated: total:)]) {
            [delegate onSyncProgressUpdated:done total:total];
        }
    }
}

void WalletModel::onChangeCalculated(beam::Amount change)
{
    NSLog(@"onChangeCalculated");
}

void WalletModel::onAllUtxoChanged(beam::wallet::ChangeAction action, const std::vector<beam::wallet::Coin>& utxos) {

    NSLog(@"onAllUtxoChanged");

    NSMutableArray *bmUtxos = [[NSMutableArray alloc] init];

    @autoreleasepool {
        for (const auto& coin : utxos)
        {
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


    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onReceivedUTXOs:)]) {
            [delegate onReceivedUTXOs:[[AppModel sharedManager]utxos]];
        }
    }
}

//void WalletModel::onAllUtxoChanged(const std::vector<beam::wallet::Coin>& utxos)
//{
//    NSLog(@"onAllUtxoChanged");
//
//    NSMutableArray *bmUtxos = [[NSMutableArray alloc] init];
//
//    @autoreleasepool {
//        for (const auto& coin : utxos)
//        {
//            BMUTXO *bmUTXO = [[BMUTXO alloc] init];
//            bmUTXO.ID = coin.m_ID.m_Idx;
//            bmUTXO.stringID = [NSString stringWithUTF8String:coin.toStringID().c_str()];
//            bmUTXO.amount = coin.m_ID.m_Value;
//            bmUTXO.realAmount = double(int64_t(coin.m_ID.m_Value)) / Rules::Coin;
//            bmUTXO.status = (int)coin.m_status;
//            bmUTXO.maturity = coin.m_maturity;
//            bmUTXO.confirmHeight = coin.m_confirmHeight;
//            bmUTXO.statusString = [GetUTXOStatusString(coin) lowercaseString];
//            bmUTXO.typeString = GetUTXOTypeString(coin);
//
//            if (coin.m_createTxId)
//            {
//                string createdTxId = to_hex(coin.m_createTxId->data(), coin.m_createTxId->size());
//                bmUTXO.createTxId = [NSString stringWithUTF8String:createdTxId.c_str()];
//            }
//
//            if (coin.m_spentTxId)
//            {
//                string spentTxId = to_hex(coin.m_spentTxId->data(), coin.m_spentTxId->size());
//                bmUTXO.spentTxId = [NSString stringWithUTF8String:spentTxId.c_str()];
//            }
//
//            [bmUtxos addObject:bmUTXO];
//        }
//    }
//
//
//    [[[AppModel sharedManager]utxos] removeAllObjects];
//    [[AppModel sharedManager] setUtxos:bmUtxos];
//
//    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
//    {
//        if ([delegate respondsToSelector:@selector(onReceivedUTXOs:)]) {
//            [delegate onReceivedUTXOs:[[AppModel sharedManager]utxos]];
//        }
//    }
////
////    [bmUtxos removeAllObjects];
////    bmUtxos = nil;
//}

void WalletModel::onAddresses(bool own, const std::vector<beam::wallet::WalletAddress>& addrs)
{
    NSLog(@"onAddresses");
    
    if (own)
    {
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
            address.categories = (categories.length == 0 ? [NSMutableArray new] : [NSMutableArray arrayWithArray:[categories componentsSeparatedByString:@","]]);
            address.label = [NSString stringWithUTF8String:walletAddr.m_label.c_str()];
            if([address.label isEqualToString:@"Default"])
            {
                address.label = [@"default" localized];
            }
            address.walletId = [NSString stringWithUTF8String:to_string(walletAddr.m_walletID).c_str()];
            
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

        for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
        {
            if ([delegate respondsToSelector:@selector(onWalletAddresses:)]) {
                [delegate onWalletAddresses:addresses];
            }
        }
    }
    else{
        this->contacts.clear();

        for (int i=0; i<addrs.size(); i++)
            this->contacts.push_back(addrs[i]);
        
        NSMutableArray <BMContact*>*contacts = [[NSMutableArray alloc] init];

        for (const auto& walletAddr : addrs)
        {
            NSString *categories = [NSString stringWithUTF8String:walletAddr.m_category.c_str()];
            if ([categories isEqualToString:@"0"]) {
                categories = @"";
            }
            
            BMAddress *address = [[BMAddress alloc] init];
            address.label = [NSString stringWithUTF8String:walletAddr.m_label.c_str()];
            address.walletId = [NSString stringWithUTF8String:to_string(walletAddr.m_walletID).c_str()];
            address.categories = (categories.length == 0 ? [NSMutableArray new] : [NSMutableArray arrayWithArray:[categories componentsSeparatedByString:@","]]);

            BMContact *contact = [[BMContact alloc] init];
            contact.address = address;
            contact.name = address.label;
            
            [contacts addObject:contact];
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
        
        [[AppModel sharedManager] setContacts:contacts];
        
        for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
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

    NSString *categories = [NSString stringWithUTF8String:walletAddr.m_category.c_str()];
    if ([categories isEqualToString:@"0"]) {
        categories = @"";
    }
    
    BMAddress *address = [[BMAddress alloc] init];
    address.duration = walletAddr.m_duration;
    address.ownerId = walletAddr.m_OwnID;
    address.createTime = walletAddr.m_createTime;
    address.categories = (categories.length == 0 ? [NSMutableArray new] : [NSMutableArray arrayWithArray:[categories componentsSeparatedByString:@","]]);
    address.label = [NSString stringWithUTF8String:walletAddr.m_label.c_str()];
    address.walletId = [NSString stringWithUTF8String:to_string(walletAddr.m_walletID).c_str()];
    
    getAsync()->saveAddress(walletAddr, true);
    
    [AppModel sharedManager].generatedNewAddressBlock(address, nil);
}

void WalletModel::onNewAddressFailed()
{
    NSError *nativeError = [NSError errorWithDomain:AppErrorDomain
                                               code:1
                                           userInfo:@{ NSLocalizedDescriptionKey:@"Failed to genereate new address" }];
    
    [AppModel sharedManager].generatedNewAddressBlock(nil, nativeError);
}

void WalletModel::onNodeConnectionChanged(bool isNodeConnected)
{
    NSLog(@"onNodeConnectionChanged %d",isNodeConnected);
    
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
        
        for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
        {
            if ([delegate respondsToSelector:@selector(onNetwotkStatusChange:)]) {
                [delegate onNetwotkStatusChange:isNodeConnected];
            }
        }
    }
}

void WalletModel::onWalletError(beam::wallet::ErrorType error)
{
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onWalletError:)]) {
            NSError *nativeError = [NSError errorWithDomain:AppErrorDomain
                                               code:NSUInteger(error)
                                           userInfo:@{ NSLocalizedDescriptionKey:GetErrorString(error) }];
            [delegate onWalletError:nativeError];
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
        for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
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
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onSendMoneyVerified)]) {
            [delegate onSendMoneyVerified];
        }
    }
    
    NSLog(@"onSendMoneyVerified");
}

void WalletModel::onCantSendToExpired()
{
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
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

    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
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

void WalletModel::onNoDeviceConnected(){
    NSLog(@"onNoDeviceConnected");
}

void WalletModel::onImportRecoveryProgress(uint64_t done, uint64_t total){
    NSLog(@"onImportRecoveryProgress");
}

void WalletModel::onShowKeyKeeperMessage(){
    NSLog(@"onShowKeyKeeperMessage");
}

void WalletModel::onHideKeyKeeperMessage(){
    NSLog(@"onHideKeyKeeperMessage");
}

void WalletModel::onShowKeyKeeperError(const std::string& error){
    NSLog(@"onShowKeyKeeperError");
}

void WalletModel::onSwapParamsLoaded(const beam::ByteBuffer& token) {
    NSLog(@"onSwapParamsLoaded");
}

void WalletModel::onImportDataFromJson(bool isOk) {
    NSLog(@"onImportDataFromJson");
}

void WalletModel::onExportDataToJson(const std::string& data) {
    NSLog(@"onExportDataToJson");
}

void WalletModel::onPostFunctionToClientContext(MessageFunction&& func) {
    NSLog(@"onPostFunctionToClientContext");
}

void WalletModel::onExportTxHistoryToCsv(const std::string& data) {
    NSLog(@"onExportTxHistoryToCsv");
}

void WalletModel::onAddressesChanged (beam::wallet::ChangeAction action, const std::vector <beam::wallet::WalletAddress > &items) {
    getAsync()->getAddresses(true);
    getAsync()->getAddresses(false);
}


void WalletModel::onExchangeRates(const std::vector<beam::wallet::ExchangeRate>& rates) {
    for (int i=0; i<rates.size(); i++) {
        auto rate = rates[i];
        
        BMCurrency *currency = [BMCurrency new];
        currency.value = rate.m_rate;
        currency.realValue = double(int64_t(rate.m_rate)) / Rules::Coin;
        
        if (rate.m_unit == beam::wallet::ExchangeRate::Currency::Usd) {
            currency.type = BMCurrencyUSD;
            currency.maximumFractionDigits = 2;
            currency.code = @"USD";
        }
        else if (rate.m_unit == beam::wallet::ExchangeRate::Currency::Bitcoin) {
            currency.type = BMCurrencyBTC;
            currency.maximumFractionDigits = 10;
            currency.code = @"BTC";
        }
        
        bool found = false;
        
        for (int j=0; j<[[[AppModel sharedManager] currencies] count]; j++) {
            if([[[AppModel sharedManager] currencies] objectAtIndex:j].type == currency.type) {
                found = true;
                [[[AppModel sharedManager] currencies] replaceObjectAtIndex:j withObject:currency];
                break;
            }
        }
        
        if (!found) {
            [[[AppModel sharedManager] currencies] addObject:currency];
        }
        
        NSLog(@"onExchangeRates %@ -> %@ = %llu", GetCurrencyString(rate.m_currency), GetCurrencyString(rate.m_unit), rate.m_rate);
    }
    
    [[AppModel sharedManager] saveCurrencies];
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onExchangeRatesChange)]) {
            [delegate onExchangeRatesChange];
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
                        bmNotification.isSended = ([[[AppModel sharedManager] presendedNotifications]  objectForKey:nId] != nil);
                    }
                }
            }
            else if(notification.m_type == beam::wallet::Notification::Type::AddressStatusChanged && Settings.sharedManager.isNotificationAddressON) {
                beam::wallet::WalletAddress address;
                if (beam::wallet::fromByteBuffer(notification.m_content, address))  {
                    NSString *pid = [NSString stringWithUTF8String:to_string(address.m_walletID).c_str()];
                    if(address.isExpired() && ![[AppModel sharedManager].deletedNotifications valueForKey:pid]) {
                        bmNotification = [BMNotification new];
                        bmNotification.nId = nId;
                        bmNotification.pId = pid;
                        bmNotification.type = ADDRESS;
                        bmNotification.isRead = notification.m_state == beam::wallet::Notification::State::Read;
                        bmNotification.createdTime = notification.m_createTime;
                        bmNotification.isSended = ([[[AppModel sharedManager] presendedNotifications]  objectForKey:nId] != nil);
                        if(!bmNotification.isSended) {
                            bmNotification.isSended = ([[[AppModel sharedManager] presendedNotifications]  objectForKey:bmNotification.pId ] != nil);
                        }
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
                bmNotification.isSended = ([[[AppModel sharedManager] presendedNotifications]  objectForKey:nId] != nil);
                
                NSLog(@"notification transaction: %@", bmNotification.pId);
            }
            else if(notification.m_type == beam::wallet::Notification::Type::BeamNews && Settings.sharedManager.isNotificationNewsON) {
                bmNotification = [BMNotification new];
                bmNotification.nId = nId;
                bmNotification.type = NEWS;
                bmNotification.isRead = false;
                bmNotification.createdTime = notification.m_createTime;
                bmNotification.isSended = ([[[AppModel sharedManager] presendedNotifications]  objectForKey:nId] != nil);
                
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
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onNotificationsChanged)]) {
            [delegate onNotificationsChanged];
        }
    }
}

NSString* WalletModel::GetCurrencyString(beam::wallet::ExchangeRate::Currency type)
{
   switch (type)
    {
        case beam::wallet::ExchangeRate::Currency::Beam:
            return @"Beam";
        case beam::wallet::ExchangeRate::Currency::Bitcoin:
            return @"Bitcoin";
        case beam::wallet::ExchangeRate::Currency::Litecoin:
            return @"Litecoin";
        case beam::wallet::ExchangeRate::Currency::Qtum:
            return @"Qtum";
        case beam::wallet::ExchangeRate::Currency::Usd:
            return @"USD";
        default:
            return @"Unexpected error!";
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

NSString* WalletModel::GetTransactionStatusString(TxDescription transaction)
{
    bool isIncome = (transaction.m_sender == false);
    
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
            if (transaction.m_selfTx)
            {
                return [[@"sending_to_own" localized] lowercaseString];
            }
            return isIncome ? [[@"waiting_for_sender" localized]lowercaseString] : [[@"waiting_for_receiver" localized]lowercaseString];
        }
        case TxStatus::Registering:{
            if (transaction.m_selfTx)
            {
                return [[@"sending_to_own" localized] lowercaseString];
            }
            return isIncome ? [[@"in_progress" localized]lowercaseString] : [[@"in_progress" localized] lowercaseString];
        }
        case TxStatus::Completed:
        {
            if (transaction.m_selfTx)
            {
                return [[@"sent_to_own" localized] lowercaseString];
            }
            return isIncome ? [[@"received" localized] lowercaseString] : [[@"sent" localized] lowercaseString];
        }
        case TxStatus::Canceled:
            return [[@"cancelled" localized] lowercaseString];
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
    NSArray *reasons = @[[[@"tx_status_unknown" localized] lowercaseString],
                         [[@"tx_status_cancelled" localized] lowercaseString],
                         [[@"tx_status_signature" localized] lowercaseString],
                         [[@"tx_status_register" localized] lowercaseString],
                         [[@"tx_status_not_valid" localized] lowercaseString],
                         [[@"tx_status_invalid_kernel" localized] lowercaseString],
                         [[@"tx_status_params" localized] lowercaseString],
                         [[@"tx_status_no_inputs" localized] lowercaseString],
                         [[@"tx_status_expired_address" localized] lowercaseString],
                         [[@"tx_status_failed_parameter" localized] lowercaseString],
                         [[@"tx_status_expired" localized] lowercaseString],
                         [[@"tx_status_not_signed" localized] lowercaseString]];

    return reasons[reason];
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
