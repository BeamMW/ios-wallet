//
//  AppModel.h
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
#import "BMWalletStatus.h"
#import "BMAddress.h"
#import "BMTransaction.h"
#import "BMUTXO.h"

@protocol WalletModelDelegate <NSObject>
@optional
-(void)onSyncProgressUpdated:(int)done total:(int)total;
-(void)onWalletError:(NSString*_Nonnull)error;
-(void)onWalletStatusChange:(BMWalletStatus*_Nonnull)status;
-(void)onNetwotkStatusChange:(BOOL)connected;
-(void)onNetwotkStartConnecting:(BOOL)connecting;
-(void)onWalletAddresses:(NSArray<BMAddress*>*_Nonnull)walletAddresses;
-(void)onGeneratedNewAddress:(BMAddress*_Nonnull)address;
-(void)onReceivedTransactions:(NSArray<BMTransaction*>*_Nonnull)transactions;
-(void)onSendMoneyVerified;
-(void)onCantSendToExpired;
-(void)onReceivedUTXOs:(NSArray<BMUTXO*>*_Nonnull)utxos;
@end

@interface AppModel : NSObject

@property (nonatomic,strong) NSHashTable * _Nonnull delegates;

@property (nonatomic,assign) BOOL isConnected;
@property (nonatomic,assign) BOOL isInternetAvailable;
@property (nonatomic,assign) BOOL isUpdating;
@property (nonatomic,assign) BOOL isConnecting;
@property (nonatomic,assign) BOOL isLoggedin;

@property (nonatomic,strong) BMWalletStatus* _Nullable walletStatus;
@property (nonatomic,strong) BMAddress* _Nullable walletAddress;
@property (nonatomic,strong) NSMutableArray<BMTransaction*>*_Nullable transactions;
@property (nonatomic,strong) NSMutableArray<BMUTXO*>*_Nullable utxos;
@property (nonatomic,strong) NSMutableArray<BMAddress*>*_Nullable walletAddresses;

+(AppModel*_Nonnull)sharedManager;

-(void)addDelegate:(id<WalletModelDelegate>_Nullable) delegate;
-(void)removeDelegate:(id<WalletModelDelegate>_Nullable) delegate;

-(BOOL)isWalletAlreadyAdded;
-(BOOL)createWallet:(NSString*_Nonnull)phrase pass:(NSString*_Nonnull)pass;
-(BOOL)openWallet:(NSString*_Nonnull)pass;
-(BOOL)canOpenWallet:(NSString*_Nonnull)pass;
-(void)resetWallet;

//-(void)refreshWallet;
-(void)getWalletStatus;
-(void)getNetworkStatus;
-(void)refreshAllInfo;

-(void)generateNewWalletAddress;
-(void)setExpires:(int)hours toAddress:(NSString*_Nonnull)address ;
-(void)setWalletComment:(NSString*_Nonnull)comment toAddress:(NSString*_Nonnull)address ;
-(NSMutableArray<BMTransaction*>*_Nonnull)getTransactionsFromAddress:(BMAddress*_Nonnull)address;
-(NSMutableArray<BMAddress*>*_Nonnull)getWalletAddresses;
-(void)editAddress:(BMAddress*_Nonnull)address;

-(BOOL)isValidAddress:(NSString*_Nullable)address;
-(BOOL)isExpiredAddress:(NSString*_Nullable)address;
-(void)deleteAddress:(NSString*_Nullable)address;

-(NSString*_Nullable)canSend:(double)amount fee:(double)fee to:(NSString*_Nullable)to;
-(void)send:(double)amount fee:(double)fee to:(NSString*_Nonnull)to comment:(NSString*_Nonnull)comment;

-(NSString*_Nonnull)getZipLogs ;

-(void)deleteTransaction:(BMTransaction*_Nonnull)transaction;
-(void)cancelTransaction:(BMTransaction*_Nonnull)transaction;
-(void)resumeTransaction:(BMTransaction*_Nonnull)transaction;

-(void)getUTXO;
-(NSMutableArray<BMTransaction*>*_Nonnull)getTransactionsFromUTXO:(BMUTXO*_Nonnull)utox;

@end
