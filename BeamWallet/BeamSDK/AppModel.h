//
// AppModel.h
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
#import "BMWalletStatus.h"
#import "BMAddress.h"
#import "BMTransaction.h"
#import "BMUTXO.h"
#import "BMContact.h"
#import "BMPaymentProof.h"
#import "Settings.h"
#import "BMCategory.h"
#import "BMDuration.h"
#import "BMPreparedTransaction.h"
#import "BMWord.h"
#import "BMLanguage.h"
#import "StringLocalize.h"
#import "BMLockScreenValue.h"
#import "BMLogValue.h"
#import "BMCurrency.h"

enum {
    BMRestoreManual = 0,
    BMRestoreAutomatic = 1,
};
typedef int BMRestoreType;

@protocol WalletModelDelegate <NSObject>
@optional
-(void)onSyncProgressUpdated:(int)done total:(int)total;
-(void)onRecoveryProgressUpdated:(int)done total:(int)total time:(int)time;
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
-(void)onNoInternetConnection;
-(void)onNodeStartChanging;
-(void)onAddedPrepareTransaction:(BMPreparedTransaction*_Nonnull)transaction;
-(void)onAddedDeleteAddress:(BMAddress*_Nonnull)address;
-(void)onAddedDeleteTransaction:(BMTransaction*_Nonnull)transaction;
-(void)onWalletCompleteVerefication;
-(void)onExchangeRatesChange;
@end

typedef void(^NewAddressGeneratedBlock)(BMAddress* _Nullable address, NSError* _Nullable error);
typedef void(^ExportOwnerKey)(NSString * _Nonnull key);

@interface AppModel : NSObject

@property (nonatomic) NewAddressGeneratedBlock _Nullable generatedNewAddressBlock;
@property (nonatomic,readwrite) NSPointerArray * _Nonnull delegates;

@property (nonatomic,assign) BOOL isConnected;
@property (nonatomic,assign) BOOL isInternetAvailable;
@property (nonatomic,assign) BOOL isUpdating;
@property (nonatomic,assign) BOOL isConnecting;
@property (nonatomic,assign) BOOL isLoggedin;
@property (nonatomic,assign) BOOL isRestoreFlow;
@property (nonatomic,assign) BOOL isNodeChanging;
@property (nonatomic,assign) BOOL isOwnNode;
@property (nonatomic,assign) BMRestoreType restoreType;

@property (nonatomic,strong) BMWalletStatus* _Nullable walletStatus;
@property (nonatomic,strong) NSMutableArray<BMTransaction*>*_Nullable transactions;
@property (nonatomic,strong) NSMutableArray<BMUTXO*>*_Nullable utxos;
@property (nonatomic,strong) NSMutableArray<BMAddress*>*_Nullable walletAddresses;
@property (nonatomic,strong) NSMutableArray<BMContact*>*_Nonnull contacts;
@property (nonatomic,strong) NSMutableArray<BMCategory*>*_Nonnull categories;
@property (nonatomic,strong) NSMutableArray<BMPreparedTransaction*>*_Nonnull preparedTransactions;
@property (nonatomic,strong) NSMutableArray<BMAddress*>*_Nonnull preparedDeleteAddresses;
@property (nonatomic,strong) NSMutableArray<BMTransaction*>*_Nonnull preparedDeleteTransactions;
@property (nonatomic,strong) NSMutableArray<BMCurrency*>*_Nonnull currencies;

@property (nonatomic, strong) NSTimer * _Nullable connectionTimer;
@property (nonatomic, strong) NSTimer * _Nullable connectionAfterOnlineTimer;

-(void)handleTimer;
-(void)startConnectionTimer:(int)seconds;

+(AppModel*_Nonnull)sharedManager;

+(NSString*_Nonnull)chooseRandomNode;

// delegates
-(void)addDelegate:(id<WalletModelDelegate>_Nullable) delegate;
-(void)removeDelegate:(id<WalletModelDelegate>_Nullable) delegate;

// create, open
-(BOOL)canRestoreWallet;
-(BOOL)isWalletAlreadyAdded;
-(BOOL)createWallet:(NSString*_Nonnull)phrase pass:(NSString*_Nonnull)pass;
-(BOOL)openWallet:(NSString*_Nonnull)pass;
-(BOOL)canOpenWallet:(NSString*_Nonnull)pass;
-(void)restore:(NSString*_Nonnull)path;
-(void)resetWallet:(BOOL)removeDatabase;
-(void)resetOnlyWallet;
-(void)restartWallet;
-(void)start;
-(BOOL)isValidPassword:(NSString*_Nonnull)pass;
-(void)changePassword:(NSString*_Nonnull)pass;
-(void)changeNodeAddress;
-(BOOL)isValidNodeAddress:(NSString*_Nonnull)string;
-(BOOL)isWalletInitialized;
-(BOOL)isWalletRunning;
-(void)exportOwnerKey:(NSString*_Nonnull)password result:(ExportOwnerKey _Nonnull)block;
-(void)checkRecoveryWallet;
-(void)startChangeWallet;
-(void)stopChangeWallet;
-(void)startChangeNode;

// updates
-(void)getWalletStatus;
-(void)getNetworkStatus;
-(void)refreshAllInfo;

// addresses
-(NSString*_Nonnull)getTransactionComment:(NSString*_Nonnull)address;
-(void)setTransactionComment:(NSString*_Nonnull)address comment:(NSString*_Nonnull)comment;
-(void)generateNewWalletAddressWithBlock:(NewAddressGeneratedBlock _Nonnull )block;
-(void)generateNewWalletAddress;
-(void)editBotAddress:(NSString*_Nonnull)address ;
-(void)setExpires:(int)hours toAddress:(NSString*_Nonnull)address;
-(void)setWalletComment:(NSString*_Nonnull)comment toAddress:(NSString*_Nonnull)address;
-(void)setWalletCategories:(NSMutableArray<NSString*>*_Nonnull)categories toAddress:(NSString*_Nonnull)address;
-(NSMutableArray<BMTransaction*>*_Nonnull)getTransactionsFromAddress:(BMAddress*_Nonnull)address;
-(NSMutableArray<BMTransaction*>*_Nonnull)getCompletedTransactionsFromAddress:(BMAddress*_Nonnull)address;
-(NSMutableArray<BMAddress*>*_Nonnull)getWalletAddresses;
-(void)editAddress:(BMAddress*_Nonnull)address;
-(void)deleteAddress:(NSString*_Nullable)address;
-(BOOL)isValidAddress:(NSString*_Nullable)address;
-(BOOL)isExpiredAddress:(NSString*_Nullable)address;
-(BOOL)isMyAddress:(NSString*_Nullable)address;
-(void)clearAllAddresses;
-(void)refreshAddresses;
-(NSString*_Nonnull)generateQRCodeString:(NSString*_Nonnull)address amount:(NSString*_Nullable)amount;
-(void)prepareDeleteAddress:(BMAddress*_Nonnull)address removeTransactions:(BOOL)removeTransactions;
-(void)cancelDeleteAddress:(NSString*_Nonnull)address;
-(void)deletePreparedAddresses:(NSString*_Nonnull)address;
-(void)addContact:(NSString*_Nonnull)addressId name:(NSString*_Nonnull)name categories:(NSArray*_Nonnull)categories;
-(BMAddress*_Nullable)findAddressByID:(NSString*_Nonnull)ID;
-(BMAddress*_Nullable)findAddressByName:(NSString*_Nonnull)name;

// send
-(NSString*_Nullable)canSend:(double)amount fee:(double)fee to:(NSString*_Nullable)to;
-(NSString*_Nullable)feeError:(double)fee;
-(NSString*_Nullable)canReceive:(double)amount fee:(double)fee;
-(void)send:(double)amount fee:(double)fee to:(NSString*_Nonnull)to comment:(NSString*_Nonnull)comment;
-(void)prepareSend:(double)amount fee:(double)fee to:(NSString*_Nonnull)to comment:(NSString*_Nonnull)comment from:(NSString*_Nullable)from saveContact:(BOOL)saveContact;
-(void)sendPreparedTransaction:(NSString*_Nonnull)transaction;
-(NSString*_Nonnull)allAmount:(double)fee;
-(double)realTotal:(double)amount fee:(double)fee;

// logs
-(NSString*_Nonnull)getZipLogs ;
-(void)clearLogs;

// transactions
-(BMTransaction*_Nullable)validatePaymentProof:(NSString*_Nullable)code;
-(void)getPaymentProof:(BMTransaction*_Nonnull)transaction;
-(void)deleteTransaction:(NSString*_Nonnull)ID;
-(void)prepareDeleteTransaction:(BMTransaction*_Nonnull)transaction;
-(void)cancelDeleteTransaction:(NSString*_Nonnull)ID;
-(void)cancelTransaction:(BMTransaction*_Nonnull)transaction;
-(void)cancelPreparedTransaction:(NSString*_Nonnull)transaction;
-(void)cancelTransactionByID:(NSString*_Nonnull)transaction;
-(void)resumeTransaction:(BMTransaction*_Nonnull)transaction;
-(NSMutableArray<BMUTXO*>*_Nonnull)getUTXOSFromTransaction:(BMTransaction*_Nonnull)transaction;
-(NSURL*_Nonnull)exportTransactionsToCSV:(NSArray<BMTransaction*>*_Nonnull)transactions;
-(void)clearAllTransactions;
-(BMTransaction*_Nullable)lastTransactionFromAddress:(NSString*_Nonnull)ID;
-(NSString*_Nullable)getFirstTransactionIdForAddress:(NSString*_Nonnull)address;
-(BOOL)hasActiveTransactions;

// utxo
-(void)getUTXO;
-(NSMutableArray<BMTransaction*>*_Nonnull)getTransactionsFromUTXO:(BMUTXO*_Nonnull)utox;

//contacts
-(BMContact*_Nullable)getContactFromId:(NSString*_Nonnull)idValue;
-(void)clearAllContacts;

//categories
-(void)deleteCategory:(BMCategory*_Nonnull)category;
-(void)editCategory:(BMCategory*_Nonnull)category;
-(void)addCategory:(BMCategory*_Nonnull)category;
-(BOOL)isNameAlreadyExist:(NSString*_Nonnull)name id:(int)ID;
-(BMCategory*_Nullable)findCategoryById:(NSString*_Nullable)ID;
-(NSMutableArray<BMAddress*>*_Nonnull)getAddressesFromCategory:(BMCategory*_Nonnull)category;
-(NSMutableArray<BMAddress*>*_Nonnull)getOnlyAddressesFromCategory:(BMCategory*_Nonnull)category;
-(NSMutableArray<BMContact*>*_Nonnull)getOnlyContactsFromCategory:(BMCategory*_Nonnull)category;
-(void)fixCategories;
-(void)clearAllCategories;
-(NSMutableArray<BMCategory*>*_Nonnull)sortedCategories;

//fork
-(BOOL)isFork;
-(int)getDefaultFeeInGroth;
-(int)getMinFeeInGroth;

-(void)completeWalletVerification;

//export
-(NSString*_Nonnull)exportData:(NSArray*_Nonnull)items;
-(BOOL)importData:(NSString*_Nonnull)jsonString;

//exchange
-(NSString*_Nonnull)exchangeValue:(double)amount;
-(NSString*_Nonnull)exchangeValueFee:(double)amount;
-(void)saveCurrencies;

@end
