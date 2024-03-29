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
#import <UIKit/UIKit.h>

#import "BMWalletStatus.h"
#import "BMAddress.h"
#import "BMTransaction.h"
#import "BMUTXO.h"
#import "BMContact.h"
#import "BMPaymentProof.h"
#import "Settings.h"
#import "BMDuration.h"
#import "BMPreparedTransaction.h"
#import "BMWord.h"
#import "BMLanguage.h"
#import "StringLocalize.h"
#import "BMLockScreenValue.h"
#import "BMLogValue.h"
#import "BMCurrency.h"
#import "BMNotification.h"
#import "BMTransactionParameters.h"
#import "BMPaymentInfo.h"
#import "BMMaxPrivacyLock.h"
#import "BMAsset.h"
#import "ExchangeManager.h"
#import "AssetsManager.h"
#import "StringManager.h"
#import "BMApp.h"

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
-(void)onNetwotkStartReconnecting;
-(void)onWalletAddresses:(NSArray<BMAddress*>*_Nonnull)walletAddresses;
-(void)onGeneratedNewAddress:(BMAddress*_Nonnull)address;
-(void)onReceivedTransactions:(NSArray<BMTransaction*>*_Nonnull)transactions;
-(void)onSendMoneyVerified;
-(void)onCantSendToExpired;
-(void)onReceivedUTXOs:(NSArray<BMUTXO*>*_Nonnull)utxos;
-(void)onContactsChange:(NSArray<BMContact*>*_Nonnull)contacts;
-(void)onReceivePaymentProof:(BMPaymentProof*_Nonnull)proof;
-(void)onLocalNodeStarted;
-(void)onNoInternetConnection;
-(void)onNodeStartChanging;
-(void)onAddedPrepareTransaction:(BMPreparedTransaction*_Nonnull)transaction;
-(void)onAddedDeleteAddress:(BMAddress*_Nonnull)address;
-(void)onAddedDeleteTransaction:(BMTransaction*_Nonnull)transaction;
-(void)onWalletCompleteVerefication;
-(void)onExchangeRatesChange;
-(void)onNotificationsChanged;
-(void)onChangeCalculated:(double)amount;
-(void)onMaxPrivacyTokensLeft:(int)tokens;
-(void)onAssetInfoChange;
-(void)onDAPPsLoaded;
@end

typedef void(^NewAddressGeneratedBlock)(BMAddress* _Nullable address, NSError* _Nullable error);
typedef void(^ExportOwnerKey)(NSString * _Nonnull key);
typedef void(^FeecalculatedBlock)(uint64_t fee, double change, uint64_t shieldedInputsFee, double max);
typedef void(^PublicAddressBlock)(NSString * _Nonnull address);
typedef void(^ExportCSVBlock)(NSString * _Nonnull data, NSURL * _Nonnull url);

@interface AppModel : NSObject

@property (nonatomic) NewAddressGeneratedBlock _Nullable generatedNewAddressBlock;

@property (nonatomic) FeecalculatedBlock _Nullable feecalculatedBlock;
@property (nonatomic) PublicAddressBlock _Nullable getPublicAddressBlock;

@property (nonatomic) ExportCSVBlock _Nullable getCSVBlock;
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
@property (nonatomic,assign) BOOL isMaxPrivacyRequest;
@property (nonatomic,assign) BOOL isConfigured;

@property (nonatomic,strong) BMWalletStatus* _Nullable walletStatus;

@property (nonatomic,strong) NSMutableArray<BMTransaction*>*_Nullable transactions;
@property (nonatomic,strong) NSMutableArray<BMUTXO*>*_Nullable utxos;
@property (nonatomic,strong) NSMutableArray<BMUTXO*>*_Nullable shildedUtxos;
@property (nonatomic,strong) NSMutableArray<BMAddress*>*_Nullable walletAddresses;
@property (nonatomic,strong) NSMutableArray<BMContact*>*_Nonnull contacts;
@property (nonatomic,strong) NSMutableArray<BMPreparedTransaction*>*_Nonnull preparedTransactions;
@property (nonatomic,strong) NSMutableArray<BMAddress*>*_Nonnull preparedDeleteAddresses;
@property (nonatomic,strong) NSMutableArray<BMTransaction*>*_Nonnull preparedDeleteTransactions;
@property (nonatomic,strong) NSMutableArray<BMNotification*>*_Nonnull notifications;
@property (nonatomic,strong) NSMutableDictionary*_Nonnull deletedNotifications;
@property (nonatomic,strong) NSMutableArray<BMApp*>*_Nonnull apps;
@property (nonatomic,strong) NSMutableDictionary*_Nonnull needSaveContacts;

@property (nonatomic, strong) NSTimer * _Nullable connectionTimer;
@property (nonatomic, strong) NSTimer * _Nullable connectionAfterOnlineTimer;

@property (nonatomic, strong) NSString * _Nullable addressGeneratedID;

-(void)handleTimer;
-(void)startConnectionTimer:(int)seconds;

+(AppModel*_Nonnull)sharedManager;

+(NSString*_Nonnull)chooseRandomNode;

// delegates
-(void)addDelegate:(id<WalletModelDelegate>_Nullable) delegate;
-(void)removeDelegate:(id<WalletModelDelegate>_Nullable) delegate;

-(void)changeTransactions;
-(void)changeNotifications;

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
-(BOOL)reconnect;
-(BOOL)isSynced;

// updates
-(void)getWalletStatus;
-(void)getNetworkStatus;
-(void)refreshAllInfo;
-(void)getWalletNotifications;
-(void)refreshAddresses;
-(void)refreshTransactions;

//token
-(BOOL)isToken:(NSString*_Nullable)address;
-(void)generateWithdrawAddress:(NewAddressGeneratedBlock _Nonnull )block;

-(void)generateNewWalletAddressWithBlockAndAmount:(int)assetId amount:(double)amount result:(NewAddressGeneratedBlock _Nonnull)block;
-(void)generateOfflineAddress:(NSString*_Nonnull)walletId assetId:(int)assetId amount:(double)amount result:(PublicAddressBlock _Nonnull)block;
-(NSString*_Nonnull)generateRegularAddress:(NSString*_Nonnull)walletId assetId:(int)assetId amount:(double)amount isPermanentAddress:(BOOL)isPermanentAddress;
-(void)generateMaxPrivacyAddress:(NSString*_Nonnull)walletId assetId:(int)assetId amount:(double)amount result:(PublicAddressBlock _Nonnull)block;


// addresses
-(BOOL)isAddress:(NSString*_Nullable)address;
-(NSString*_Nonnull)getTransactionComment:(NSString*_Nonnull)address;
-(void)setTransactionComment:(NSString*_Nonnull)address comment:(NSString*_Nonnull)comment;
-(void)generateNewWalletAddressWithBlock:(NewAddressGeneratedBlock _Nonnull )block;
-(void)generateNewWalletAddress;
-(void)editBotAddress:(NSString*_Nonnull)address ;
-(void)setExpires:(int)hours toAddress:(NSString*_Nonnull)address;
-(void)setWalletComment:(NSString*_Nonnull)comment toAddress:(NSString*_Nonnull)address;
-(NSMutableArray<BMTransaction*>*_Nonnull)getTransactionsFromAddress:(BMAddress*_Nonnull)address;
-(BOOL)hasActiveTransactionsFromAddress:(BMAddress*_Nonnull)address;
-(NSMutableArray<BMTransaction*>*_Nonnull)getCompletedTransactionsFromAddress:(BMAddress*_Nonnull)address;
-(void)editAddress:(BMAddress*_Nonnull)address;
-(void)saveToken:(NSString*_Nonnull)walletID token:(NSString*_Nonnull)token;
-(void)deleteAddress:(NSString*_Nullable)address;
-(BOOL)isValidAddress:(NSString*_Nullable)address;
-(BOOL)isExpiredAddress:(NSString*_Nullable)address;
-(BOOL)isMyAddress:(NSString*_Nullable)address identity:(NSString*_Nullable)identity;
-(void)clearAllAddresses;
-(NSString*_Nonnull)generateQRCodeString:(NSString*_Nonnull)address amount:(NSString*_Nullable)amount;
-(void)prepareDeleteAddress:(BMAddress*_Nonnull)address removeTransactions:(BOOL)removeTransactions;
-(void)cancelDeleteAddress:(NSString*_Nonnull)address;
-(void)deletePreparedAddresses:(NSString*_Nonnull)address;
-(void)addContact:(NSString*_Nonnull)addressId address:(NSString*_Nullable)address name:(NSString*_Nonnull)name identidy:(NSString*_Nullable)identidy;
-(BOOL)containsIgnoredContact:(NSString*_Nonnull) addressId;
-(BMAddress*_Nullable)findAddressByID:(NSString*_Nonnull)ID;
-(BMAddress*_Nullable)findAddressByName:(NSString*_Nonnull)name;
-(void)getPublicAddress:(PublicAddressBlock _Nonnull )block;
-(NSString*_Nonnull)getAddressTypeString:(BMAddressType)type;

// send
-(NSString*_Nullable)canSend:(double)amount assetId:(int)assetId fee:(double)fee to:(NSString*_Nullable)to maxAmount:(double)maxAmount checkAddress:(BOOL)checkAddress;

-(NSString*_Nullable)sendError:(double)amount assetId:(int)assetId fee:(double)fee checkMinAmount:(BOOL)check;
-(NSString*_Nullable)feeError:(double)fee;
-(NSString*_Nullable)canReceive:(double)amount fee:(double)fee;
-(void)send:(double)amount fee:(double)fee assetId:(int)assetId to:(NSString*_Nonnull)to from:(NSString*_Nonnull)from comment:(NSString*_Nonnull)comment isOffline:(BOOL)isOffline;
-(void)prepareSendNew:(double)amount fee:(double)fee assetId:(int)assetId to:(NSString*_Nonnull)to comment:(NSString*_Nonnull)comment contactName:(NSString*_Nonnull)contactName maxPrivacy:(BOOL)maxPrivacy;
-(void)prepareSend:(double)amount fee:(double)fee assetId:(int)assetId to:(NSString*_Nonnull)to comment:(NSString*_Nonnull)comment from:(NSString*_Nullable)from saveContact:(BOOL)saveContact isOffline:(BOOL)isOffline;

-(void)sendPreparedTransaction:(NSString*_Nonnull)transaction;
-(NSString*_Nonnull)allAmount:(double)fee assetId:(int)assetId;
-(double)realTotal:(double)amount fee:(double)fee assetId:(int)assetId;
-(double)remaining:(double)amount fee:(double)fee assetId:(int)assetId;
-(double)remainingBeam:(double)amount fee:(double)fee;
-(BMTransactionParameters*_Nonnull)getTransactionParameters:(NSString*_Nonnull)token;
-(void)calculateFee:(double)amount assetId:(int)assetId fee:(double)fee isShielded:(BOOL) isShielded result:(FeecalculatedBlock _Nonnull )block;

// logs
-(NSString*_Nonnull)getZipLogs ;
-(void)clearLogs;

// transactions
-(BMPaymentInfo*_Nullable)validatePaymentProof:(NSString*_Nullable)code;
-(void)getPaymentProof:(BMTransaction*_Nonnull)transaction;
-(void)deleteTransaction:(NSString*_Nonnull)ID;
-(void)prepareDeleteTransaction:(BMTransaction*_Nonnull)transaction;
-(void)cancelDeleteTransaction:(NSString*_Nonnull)ID;
-(void)cancelTransaction:(BMTransaction*_Nonnull)transaction;
-(void)cancelPreparedTransaction:(NSString*_Nonnull)transaction;
-(void)cancelTransactionByID:(NSString*_Nonnull)transaction;
-(void)resumeTransaction:(BMTransaction*_Nonnull)transaction;
-(NSMutableArray<BMUTXO*>*_Nonnull)getUTXOSFromTransaction:(BMTransaction*_Nonnull)transaction;
-(void)exportTransactionsToCSV:(ExportCSVBlock _Nonnull)block;
-(void)clearAllTransactions;
-(BMTransaction*_Nullable)lastTransactionFromAddress:(NSString*_Nonnull)ID;
-(NSString*_Nullable)getFirstTransactionIdForAddress:(NSString*_Nonnull)address;
-(BOOL)hasActiveTransactions;
-(BMTransaction*_Nullable)transactionById:(NSString*_Nonnull)ID;
-(void)calculateChange:(double)amount fee:(double)fee;
-(void)setTransactionStatusToFailed:(NSString*_Nonnull)ID;
-(BMPaymentInfo*_Nullable)getPaymentProofInfo:(NSString*_Nonnull)proof;

// utxo
-(void)getUTXO;
-(NSMutableArray<BMTransaction*>*_Nonnull)getTransactionsFromUTXO:(BMUTXO*_Nonnull)utox;

//contacts
-(BMContact*_Nullable)getContactFromId:(NSString*_Nonnull)idValue;
-(void)clearAllContacts;
-(void)addIgnoredContact:(NSString*_Nonnull) addressId;
-(void)refreshContacts;

//fork
-(BOOL)isFork;
-(int)getDefaultFeeInGroth;
-(int)getMinFeeInGroth;
-(int)getMinMaxPrivacyFeeInGroth;

-(void)completeWalletVerification;

//export
-(NSString*_Nonnull)exportData:(NSArray*_Nonnull)items;
-(BOOL)importData:(NSString*_Nonnull)jsonString;


-(BOOL)checkIsOwnNode;

//notifications
-(int)getUnreadNotificationsCount;
-(int)getUnsendedNotificationsCount;
-(BMNotification*_Nullable)getUnsendedNotification;
-(BOOL)allUnsendedIsAddresses;
-(void)sendNotifications;
-(void)readNotification:(NSString*_Nonnull) notifId;
-(void)readNotificationByObject:(NSString*_Nonnull) objectId;
-(void)clearNotifications;
-(void)deleteNotification:(NSString*_Nonnull) notifId;
-(void)deleteAllNotifications;
-(BMNotification*_Nullable)getLastVersionNotification;
-(void)readAllNotifications;

-(void)setMaxPrivacyLockTime:(int)hours;
-(void)setMinConfirmations:(uint32_t)count;

-(NSString*_Nonnull)getMaturityHoursLeft:(BMUTXO*_Nonnull)utxo;
-(UInt64)getMaturityHours:(BMUTXO*_Nonnull)utxo;

-(void)rescan;
-(void)enableBodyRequests:(BOOL)value;
-(void)resetEstimateProgress;
-(UInt64)getEstimateProgress:(UInt64)done total:(UInt64)total;

-(double)grothToBeam:(uint64_t)groth;


//DAO
-(void)loadApps;
-(void)stopDAO;
-(void)startApp:(UIViewController*_Nonnull)controller app:(BMApp*_Nonnull)app;
-(void)startBeamXDaoApp:(UINavigationController*_Nonnull)controller app:(BMApp*_Nonnull)app;
-(void)sendDAOApiResult:(NSString*_Nonnull)json;
-(void)approveContractInfo:(NSString*_Nonnull)json info:(NSString*_Nonnull)info
                      amounts:(NSString*_Nonnull)amounts;
-(void)getAssetInfoAsync:(int)assetId;

-(BMApp*_Nonnull)DAOBeamXApp;
-(BMApp*_Nonnull)daoGalleryApp;
-(BMApp*_Nonnull)daoFaucetApp;
-(BMApp*_Nonnull)votingApp;

@end
