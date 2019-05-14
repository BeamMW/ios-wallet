//
//  WalletModel.m
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

#import "WalletModel.h"
#import "AppModel.h"

#include <boost/regex.hpp>

#include "utility/logger.h"
#include "utility/bridge.h"
#include "utility/io/asyncevent.h"
#include "utility/helpers.h"
#include "utility/common.h"

using namespace beam;
using namespace beam::io;
using namespace std;

NSString *const AppErrorDomain = @"beam.mw";


WalletModel::WalletModel(IWalletDB::Ptr walletDB, const std::string& nodeAddr, beam::io::Reactor::Ptr reactor)
: WalletClient(walletDB, nodeAddr, reactor)
{
    
}

WalletModel::~WalletModel()
{
    
}

std::string txIDToString(const TxID& txId)
{
    return to_hex(txId.data(), txId.size());
}

void WalletModel::onStatus(const WalletStatus& status)
{
   // NSLog(@"onStatus");
    
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

void WalletModel::onTxStatus(beam::ChangeAction action, const std::vector<beam::TxDescription>& items)
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
        transaction.status = GetTransactionStatusString(item);
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
    
    if (done == total)
    {
        [[AppModel sharedManager] onSyncWithLocalNodeCompleted];
    }
}

void WalletModel::onChangeCalculated(beam::Amount change)
{
    NSLog(@"onChangeCalculated");
}

void WalletModel::onAllUtxoChanged(const std::vector<beam::Coin>& utxos)
{
  //  NSLog(@"onAllUtxoChanged");
    
    NSMutableArray *bmUtxos = [[NSMutableArray alloc] init];
    
    @autoreleasepool {
        for (const auto& coin : utxos)
        {
            BMUTXO *bmUTXO = [[BMUTXO alloc] init];
            bmUTXO.ID = coin.m_ID.m_Idx;
            bmUTXO.stringID = [NSString stringWithUTF8String:coin.toStringID().c_str()];
            bmUTXO.amount = coin.m_ID.m_Value;
            bmUTXO.realAmount = double(int64_t(coin.m_ID.m_Value)) / Rules::Coin;
            bmUTXO.status = coin.m_status;
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

    
    [[[AppModel sharedManager]utxos] removeAllObjects];
    [[AppModel sharedManager] setUtxos:bmUtxos];
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onReceivedUTXOs:)]) {
            [delegate onReceivedUTXOs:[[AppModel sharedManager]utxos]];
        }
    }
//    
//    [bmUtxos removeAllObjects];
//    bmUtxos = nil;
}

void WalletModel::onAddresses(bool own, const std::vector<beam::WalletAddress>& addrs)
{
    NSLog(@"onAddresses");
    
    if (own)
    {
        NSMutableArray *addresses = [[NSMutableArray alloc] init];
        
        for (const auto& walletAddr : addrs)
        {
            BMAddress *address = [[BMAddress alloc] init];
            address.duration = walletAddr.m_duration;
            address.ownerId = walletAddr.m_OwnID;
            address.createTime = walletAddr.m_createTime;
            address.category = [NSString stringWithUTF8String:walletAddr.m_category.c_str()];
            address.label = [NSString stringWithUTF8String:walletAddr.m_label.c_str()];
            address.walletId = [NSString stringWithUTF8String:to_string(walletAddr.m_walletID).c_str()];
            
            [addresses addObject:address];
        }
        
        [[AppModel sharedManager] setWalletAddresses:addresses];
        
        for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
        {
            if ([delegate respondsToSelector:@selector(onWalletAddresses:)]) {
                [delegate onWalletAddresses:addresses];
            }
        }
    }
    else{
        NSMutableArray *contacts = [[NSMutableArray alloc] init];

        for (const auto& walletAddr : addrs)
        {
            BMAddress *address = [[BMAddress alloc] init];
            address.label = [NSString stringWithUTF8String:walletAddr.m_label.c_str()];
            address.walletId = [NSString stringWithUTF8String:to_string(walletAddr.m_walletID).c_str()];
            address.category = [NSString stringWithUTF8String:walletAddr.m_category.c_str()];

            BMContact *contact = [[BMContact alloc] init];
            contact.address = address;
            contact.name = address.label;
            
            [contacts addObject:contact];
        }
        
        [[AppModel sharedManager] setContacts:contacts];
        
        for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
        {
            if ([delegate respondsToSelector:@selector(onContactsChange:)]) {
                [delegate onContactsChange:contacts];
            }
        }
    }
}

void WalletModel::onGeneratedNewAddress(const beam::WalletAddress& walletAddr)
{
    NSLog(@"onGeneratedNewAddress");

    BMAddress *address = [[BMAddress alloc] init];
    address.duration = walletAddr.m_duration;
    address.ownerId = walletAddr.m_OwnID;
    address.createTime = walletAddr.m_createTime;
    address.category = [NSString stringWithUTF8String:walletAddr.m_category.c_str()];
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

void WalletModel::onChangeCurrentWalletIDs(beam::WalletID senderID, beam::WalletID receiverID)
{
    NSLog(@"onChangeCurrentWalletIDs");
}

void WalletModel::onNodeConnectionChanged(bool isNodeConnected)
{
    NSLog(@"onNodeConnectionChanged %d",isNodeConnected);
    
    if (![[AppModel sharedManager] isInternetAvailable] && isNodeConnected) {
        isNodeConnected = NO;
    }
    
    [[AppModel sharedManager] setIsConnected:isNodeConnected];
    
    [[AppModel sharedManager] setIsConnecting:NO];
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onNetwotkStatusChange:)]) {
            [delegate onNetwotkStatusChange:isNodeConnected];
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
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onWalletError:)]) {
            NSError *nativeError = [NSError errorWithDomain:AppErrorDomain
                                                       code:NSUInteger(12)
                                                   userInfo:@{ NSLocalizedDescriptionKey:@"Failed to start wallet" }];
            [delegate onWalletError:nativeError];
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

void WalletModel::onPaymentProofExported(const beam::TxID& txID, const beam::ByteBuffer& proof)
{
    NSLog(@"onPaymentProofExported");
    
    string str;
    str.resize(proof.size() * 2);

    //beam::to_hex(str.data(), proof.data(), proof.size());
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

void WalletModel::onCoinsByTx(const std::vector<beam::Coin>& coins)
{
    
}

void WalletModel::onAddressChecked(const std::string& addr, bool isValid)
{
    
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
            return @"pending";
        case TxStatus::InProgress:
            return isIncome ? @"waiting for sender" : @"waiting for receiver";
        case TxStatus::Registering:
            return isIncome ? @"receiving" : @"sending";
        case TxStatus::Completed:
        {
            if (transaction.m_selfTx)
            {
                return @"completed";
            }
            return isIncome ? @"received" : @"sent";
        }
        case TxStatus::Cancelled:
            return @"cancelled";
        case TxStatus::Failed:
            {
                if (transaction.m_failureReason == TxFailureReason::TransactionExpired)
                {
                    return @"expired";
                }
            }
            return @"failed";
        default:
            break;
    }
    
    return @"unknown";
}

NSString* WalletModel::GetTransactionFailurString(TxFailureReason reason)
{
    NSArray *reasons = @[@"Unknown reason",@"Transaction was cancelled",@"Peer's signature in not valid", @"Failed to register transaction", @"Transaction is not valid", @"Invalid kernel proof provided", @"Failed to send tx parameters", @"No inputs", @"Address is expired",@"Failed to get parameter",@"Transaction has expired",@"Payment not signed by the receiver"];

    return reasons[reason];
}

NSString* WalletModel::GetUTXOStatusString(Coin coin)
{
    switch (coin.m_status)
    {
        case Coin::Available:
            return @"Available";
        case Coin::Maturing:
            return @"Maturing";
        case Coin::Unavailable:
            return @"Unavailable";
        case Coin::Outgoing:
            return @"In progress\n(outgoing)";
        case Coin::Incoming: {
            if (coin.m_ID.m_Type == Key::Type::Change)
            {
                return @"In progress\n(change)";
            }
            return @"In progress\n(incoming)";
        }
            
        case Coin::Spent:
            return @"Spent";
        default:
            break;
    }
    
    return @"unknown";
}

NSString* WalletModel::GetUTXOTypeString(beam::Coin coin) {
    switch (coin.m_ID.m_Type)
    {
        case Key::Type::Comission:
            return @"Transaction fee";
        case Key::Type::Coinbase:
            return @"Coinbase";
        case Key::Type::Regular:
            return @"Regular";
        case Key::Type::Change:
            return @"Change";
        case Key::Type::Treasury: {
            return @"Treasury";
        }
    }
    
    return @"unknown";
}
