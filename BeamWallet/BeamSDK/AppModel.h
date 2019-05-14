//
// AppModel.h
// BeamTest
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
#import "BMWalletStatus.h"
#import "BMAddress.h"
#import "BMTransaction.h"
#import "BMUTXO.h"
#import "BMContact.h"
#import "BMPaymentProof.h"
#import "Settings.h"
#import "BMCategory.h"
#import "BMDuration.h"

@protocol WalletModelDelegate <NSObject>
@optional
-(void)onSyncProgressUpdated:(int)done total:(int)total;
-(void)onWalletError:(NSError*_Nonnull)error;
-(void)onWalletStatusChange:(BMWalletStatus*_Nonnull)status;
-(void)onNetwotkStatusChange:(BOOL)connected;
-(void)onNetwotkStartConnecting:(BOOL)connecting;
-(void)onWalletAddresses:(NSArray<BMAddress*>*_Nonnull)walletAddresses;
-(void)onGeneratedNewAddress:(BMAddress*_Nonnull)address;
-(void)onReceivedTransactions:(NSArray<BMTransaction*>*_Nonnull)transactions;
-(void)onSendMoneyVerified;
-(void)onCantSendToExpired;
-(void)onReceivedUTXOs:(NSArray<BMUTXO*>*_Nonnull)utxos;
-(void)onContactsChange:(NSArray<BMContact*>*_Nonnull)contacts;
-(void)onReceivePaymentProof:(BMPaymentProof*_Nonnull)proof;
-(void)onLocalNodeStarted;
-(void)onCategoriesChange;
@end

typedef void(^NewAddressGeneratedBlock)(BMAddress* _Nullable address, NSError* _Nullable error);

@interface AppModel : NSObject

@property (nonatomic) NewAddressGeneratedBlock _Nullable generatedNewAddressBlock;
@property (nonatomic,strong) NSHashTable * _Nonnull delegates;

@property (nonatomic,assign) BOOL isConnected;
@property (nonatomic,assign) BOOL isInternetAvailable;
@property (nonatomic,assign) BOOL isUpdating;
@property (nonatomic,assign) BOOL isConnecting;
@property (nonatomic,assign) BOOL isLoggedin;
@property (nonatomic,assign) BOOL isLocalNodeStarted;
@property (nonatomic,assign) BOOL isRestoreFlow;
@property (nonatomic,assign) BOOL isForgotPasswordFlow;

@property (nonatomic,strong) BMWalletStatus* _Nullable walletStatus;
@property (nonatomic,strong) NSMutableArray<BMTransaction*>*_Nullable transactions;
@property (nonatomic,strong) NSMutableArray<BMUTXO*>*_Nullable utxos;
@property (nonatomic,strong) NSMutableArray<BMAddress*>*_Nullable walletAddresses;
@property (nonatomic,strong) NSMutableArray<BMContact*>*_Nonnull contacts;
@property (nonatomic,strong) NSMutableArray<BMCategory*>*_Nonnull categories;

+(AppModel*_Nonnull)sharedManager;

// delegates
-(void)addDelegate:(id<WalletModelDelegate>_Nullable) delegate;
-(void)removeDelegate:(id<WalletModelDelegate>_Nullable) delegate;

// create, open
-(BOOL)canRestoreWallet;
-(BOOL)isWalletAlreadyAdded;
-(BOOL)createWallet:(NSString*_Nonnull)phrase pass:(NSString*_Nonnull)pass;
-(BOOL)openWallet:(NSString*_Nonnull)pass;
-(BOOL)canOpenWallet:(NSString*_Nonnull)pass;
-(void)resetWallet:(BOOL)removeDatabase;
-(void)startForgotPassword;
-(void)stopForgotPassword;
-(void)cancelForgotPassword;
-(BOOL)isValidPassword:(NSString*_Nonnull)pass;
-(void)changePassword:(NSString*_Nonnull)pass;
-(void)onSyncWithLocalNodeCompleted;
-(void)changeNodeAddress;
-(BOOL)isValidNodeAddress:(NSString*_Nonnull)string;
-(BOOL)isWalletInitialized;

// updates
-(void)getWalletStatus;
-(void)getNetworkStatus;
-(void)refreshAllInfo;

// addresses
-(void)generateNewWalletAddressWithBlock:(NewAddressGeneratedBlock _Nonnull )block;
-(void)generateNewWalletAddress;
-(void)editBotAddress:(NSString*_Nonnull)address ;
-(void)setExpires:(int)hours toAddress:(NSString*_Nonnull)address;
-(void)setWalletComment:(NSString*_Nonnull)comment toAddress:(NSString*_Nonnull)address ;
-(NSMutableArray<BMTransaction*>*_Nonnull)getTransactionsFromAddress:(BMAddress*_Nonnull)address;
-(NSMutableArray<BMAddress*>*_Nonnull)getWalletAddresses;
-(void)editAddress:(BMAddress*_Nonnull)address;
-(void)deleteAddress:(NSString*_Nullable)address;
-(BOOL)isValidAddress:(NSString*_Nullable)address;
-(BOOL)isExpiredAddress:(NSString*_Nullable)address;
-(BOOL)isMyAddress:(NSString*_Nullable)address;
-(void)clearAllAddresses;
-(NSString*_Nonnull)generateQRCodeString:(NSString*_Nonnull)address amount:(NSString*_Nullable)amount;

// send
-(NSString*_Nullable)canSend:(double)amount fee:(double)fee to:(NSString*_Nullable)to;
-(NSString*_Nullable)canReceive:(double)amount fee:(double)fee;
-(void)send:(double)amount fee:(double)fee to:(NSString*_Nonnull)to comment:(NSString*_Nonnull)comment;
-(NSString*_Nonnull)allAmount:(double)fee;


// logs
-(NSString*_Nonnull)getZipLogs ;

// transactions
-(BMTransaction*_Nullable)validatePaymentProof:(NSString*_Nullable)code;
-(void)getPaymentProof:(BMTransaction*_Nonnull)transaction;
-(void)deleteTransaction:(BMTransaction*_Nonnull)transaction;
-(void)cancelTransaction:(BMTransaction*_Nonnull)transaction;
-(void)resumeTransaction:(BMTransaction*_Nonnull)transaction;
-(NSMutableArray<BMUTXO*>*_Nonnull)getUTXOSFromTransaction:(BMTransaction*_Nonnull)transaction;
-(void)exportTransactionsToCSV:(void(^_Nonnull)(NSURL*_Nonnull))callback;
-(void)clearAllTransactions;

// utxo
-(void)getUTXO;
-(NSMutableArray<BMUTXO*>*_Nonnull)getUTXOWithPadding:(BOOL)active page:(int)page perPage:(int)perPage;
-(NSMutableArray<BMTransaction*>*_Nonnull)getTransactionsFromUTXO:(BMUTXO*_Nonnull)utox;

//contacts
-(BMContact*_Nullable)getContactFromId:(NSString*_Nonnull)idValue;
-(void)clearAllContacts;

//categories
-(void)deleteCategory:(BMCategory*_Nonnull)category;
-(void)editCategory:(BMCategory*_Nonnull)category;
-(void)addCategory:(BMCategory*_Nonnull)category;
-(BOOL)isNameAlreadyExist:(NSString*_Nonnull)name id:(int)ID;
-(BMCategory*_Nullable)findCategoryById:(NSString*_Nonnull)ID;
-(BMCategory*_Nullable)findCategoryByAddress:(NSString*_Nonnull)ID;
-(NSMutableArray<BMAddress*>*_Nonnull)getAddressFromCategory:(BMCategory*_Nonnull)category;

@end
