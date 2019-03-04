//
//  WalletModel.m
//  BeamTest
//
//  Created by Denis on 2/28/19.
//  Copyright © 2019 Denis. All rights reserved.
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
}

void WalletModel::onTxStatus(beam::ChangeAction action, const std::vector<beam::TxDescription>& items)
{
    NSLog(@"onTxStatus");
}

void WalletModel::onSyncProgressUpdated(int done, int total)
{
    [[AppModel sharedManager].walletDelegate onSyncProgressUpdated:done total:total];
    
    NSLog(@"onSyncProgressUpdated %d/%d",done, total);
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
}

void WalletModel::onChangeCurrentWalletIDs(beam::WalletID senderID, beam::WalletID receiverID)
{
    NSLog(@"onChangeCurrentWalletIDs");
}

void WalletModel::onNodeConnectionChanged(bool isNodeConnected)
{
    NSLog(@"onNodeConnectionChanged %d",isNodeConnected);
}

void WalletModel::onWalletError(beam::wallet::ErrorType error)
{
    [[AppModel sharedManager].walletDelegate onWalletError:GetErrorString(error)];
    
    NSLog(@"onWalletError %hhu",error);
}

void WalletModel::FailedToStartWallet()
{
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
