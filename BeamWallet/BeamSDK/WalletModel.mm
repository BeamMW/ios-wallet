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

#include "utility/logger.h"

#include "common.h"

using namespace beam;
using namespace beam::io;
using namespace std;

WalletModel::WalletModel(IWalletDB::Ptr walletDB, const std::string& nodeAddr)
: WalletClient(walletDB, nodeAddr)
{
}

WalletModel::~WalletModel()
{

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

    [[AppModel sharedManager] setWalletStatus:walletStatus];
    if ([[AppModel sharedManager].walletDelegate respondsToSelector:@selector(onWalletStatusChange:)]) {
        [[AppModel sharedManager].walletDelegate onWalletStatusChange:walletStatus];
    }
}

void WalletModel::onTxStatus(beam::ChangeAction action, const std::vector<beam::TxDescription>& items)
{
    NSMutableArray *transactions = [NSMutableArray new];
    
    for (const auto& item : items)
    {
        BMTransaction *transaction = [BMTransaction new];
        transaction.realAmount = double(int64_t(item.m_amount)) / Rules::Coin;
        transaction.createdTime = item.m_createTime;
        transaction.isIncome = (item.m_sender == false);
        transaction.status = GetTransactionStatusString(item.m_status,transaction.isIncome);
        transaction.failureReason = GetTransactionFailurString(item.m_failureReason);

        [transactions addObject:transaction];
    }
    
    [[AppModel sharedManager] setTransactions:transactions];
    if ([[AppModel sharedManager].walletDelegate respondsToSelector:@selector(onReceivedTransactions:)]) {
        [[AppModel sharedManager].walletDelegate onReceivedTransactions:transactions];
    }
    
    NSLog(@"onTxStatus");
}

void WalletModel::onSyncProgressUpdated(int done, int total)
{
    NSLog(@"onSyncProgressUpdated %d/%d",done, total);

    if ([[AppModel sharedManager].walletDelegate respondsToSelector:@selector(onSyncProgressUpdated: total:)]) {
        [[AppModel sharedManager].walletDelegate onSyncProgressUpdated:done total:total];
     }
    
}

void WalletModel::onChangeCalculated(beam::Amount change)
{
    NSLog(@"onChangeCalculated");
}

void WalletModel::onAllUtxoChanged(const std::vector<beam::Coin>& utxos)
{
    NSLog(@"onAllUtxoChanged");
}

void WalletModel::onAddresses(bool own, const std::vector<beam::WalletAddress>& addrs)
{
    printf("onAddresses");
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
    
    [[AppModel sharedManager] setWalletAddress:address];
    
    if ([[AppModel sharedManager].walletDelegate respondsToSelector:@selector(onGeneratedNewAddress:)]) {
        [[AppModel sharedManager].walletDelegate onGeneratedNewAddress:address];
    }
}

void WalletModel::onChangeCurrentWalletIDs(beam::WalletID senderID, beam::WalletID receiverID)
{
    NSLog(@"onChangeCurrentWalletIDs");
}

void WalletModel::onNodeConnectionChanged(bool isNodeConnected)
{
    NSLog(@"onNodeConnectionChanged %d",isNodeConnected);
    
    if (![[AppModel sharedManager] isReachable] && isNodeConnected) {
        isNodeConnected = NO;
    }
    
    [[AppModel sharedManager] setIsConnected:isNodeConnected];
    
    if ([[AppModel sharedManager].walletDelegate respondsToSelector:@selector(onNetwotkStatusChange:)]) {
        [[AppModel sharedManager].walletDelegate onNetwotkStatusChange:isNodeConnected];
    }
}

void WalletModel::onWalletError(beam::wallet::ErrorType error)
{
    if ([[AppModel sharedManager].walletDelegate respondsToSelector:@selector(onWalletError:)]) {
        [[AppModel sharedManager].walletDelegate onWalletError:GetErrorString(error)];
    }
    
    
    NSLog(@"onWalletError %hhu",error);
}

void WalletModel::FailedToStartWallet()
{
    if ([[AppModel sharedManager].walletDelegate respondsToSelector:@selector(onWalletError:)]) {
        [[AppModel sharedManager].walletDelegate onWalletError:@"Failed to start wallet"];
    }
    
    NSLog(@"FailedToStartWallet");
}

void WalletModel::onSendMoneyVerified()
{
    NSLog(@"onSendMoneyVerified");
}

void WalletModel::onCantSendToExpired()
{
    NSLog(@"onCantSendToExpired");
}

void WalletModel::onPaymentProofExported(const beam::TxID& txID, const beam::ByteBuffer& proof)
{
    NSLog(@"onPaymentProofExported");
}

NSString* WalletModel::GetErrorString(beam::wallet::ErrorType type)
{
    // TODO: add more detailed error description
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

NSString* WalletModel::GetTransactionStatusString(TxStatus status, bool income)
{
    switch (status)
    {
        case TxStatus::Pending:
            return @"pending";
        case TxStatus::InProgress:
            return income ? @"waiting for sender" : @"waiting for receiver";
        case TxStatus::Registering:
            return income ? @"receiving" : @"sending";
        case TxStatus::Completed:
        {
//            if (m_tx.m_selfTx)
//            {
//                return tr("completed");
//            }
            return income ? @"received" : @"sent";
        }
        case TxStatus::Cancelled:
            return @"cancelled";
        case TxStatus::Failed:
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


