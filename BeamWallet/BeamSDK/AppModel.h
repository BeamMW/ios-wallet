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

@protocol WalletModelDelegate <NSObject>
@optional
-(void)onSyncProgressUpdated:(int)done total:(int)total;
-(void)onWalletError:(NSString*_Nonnull)error;
-(void)onWalletStatusChange:(BMWalletStatus*_Nonnull)status;
-(void)onNetwotkStatusChange:(BOOL)connected;
-(void)onGeneratedNewAddress:(BMAddress*_Nonnull)address;
-(void)onReceivedTransactions:(NSArray<BMTransaction*>*_Nonnull)transactions;
-(void)onSendMoneyVerified;
-(void)onCantSendToExpired;
@end

@interface AppModel : NSObject

@property (nonatomic,strong) NSHashTable * _Nonnull delegates;

@property (nonatomic,assign) BOOL isConnected;
@property (nonatomic,assign) BOOL isInternetAvailable;

@property (nonatomic,strong) BMWalletStatus* _Nullable walletStatus;
@property (nonatomic,strong) BMAddress* _Nullable walletAddress;
@property (nonatomic,strong) NSMutableArray<BMTransaction*>*_Nullable transactions;

+(AppModel*_Nonnull)sharedManager;

-(void)addDelegate:(id<WalletModelDelegate>_Nullable) delegate;
-(void)removeDelegate:(id<WalletModelDelegate>_Nullable) delegate;

-(BOOL)isWalletAlreadyAdded;
-(BOOL)createWallet:(NSString*_Nonnull)phrase pass:(NSString*_Nonnull)pass;
-(BOOL)openWallet:(NSString*_Nonnull)pass;
-(BOOL)canOpenWallet:(NSString*_Nonnull)pass;
-(void)resetWallet;

-(void)refreshWallet;
-(void)getWalletStatus;
-(void)getNetworkStatus;

-(void)generateNewWalletAddress;
-(void)setExpires:(int)hours toAddress:(NSString*_Nonnull)address ;
-(void)setWalletComment:(NSString*_Nonnull)comment toAddress:(NSString*_Nonnull)address ;

-(BOOL)isValidAddress:(NSString*_Nullable)address;

-(NSString*_Nullable)canSend:(double)amount fee:(double)fee to:(NSString*_Nullable)to;
-(void)send:(double)amount fee:(double)fee to:(NSString*_Nonnull)to comment:(NSString*_Nonnull)comment;

-(NSString*_Nonnull)getZipLogs ;

@end
