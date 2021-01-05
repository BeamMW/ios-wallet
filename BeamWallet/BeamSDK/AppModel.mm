//
// AppModel.m
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
#import "Reachability.h"
#import "AppModel.h"
#import "MnemonicModel.h"
#import "WalletModel.h"
#import "StringStd.h"
#import "DiskStatusManager.h"
#import "CurrencyFormatter.h"
#import "RecoveryProgress.h"
#import <SVProgressHUD/SVProgressHUD.h>
#include "nlohmann/json.hpp"
#include <regex>

#import <SSZipArchive/SSZipArchive.h>

#include "wallet/core/wallet.h"

#include "wallet/core/wallet_db.h"
#include "wallet/core/wallet_network.h"
#include "wallet/client/wallet_model_async.h"
#include "wallet/client/wallet_client.h"
#include "wallet/core/default_peers.h"

#include "core/block_rw.h"
#include "build/core/version.h"

#include "utility/bridge.h"
#include "utility/string_helpers.h"

#include "mnemonic/mnemonic.h"

#include "wallet/transactions/lelantus/unlink_transaction.h"
#include "wallet/transactions/lelantus/push_transaction.h"
#include "wallet/transactions/lelantus/pull_transaction.h"

#include "wallet/core/simple_transaction.h"
#include "wallet/core/common_utils.h"
#include "wallet/core/common.h"
#include "common.h"
#include <sys/sysctl.h>
#import <sys/utsname.h>

using namespace beam;
using namespace ECC;
using namespace beam;
using namespace beam::io;
using namespace beam::wallet;
using namespace std;

static int proofSize = 330;
static NSString *categoriesKey = @"categoriesKey";
static NSString *transactionCommentsKey = @"transaction_comment";
static NSString *restoreFlowKey = @"restoreFlowKey";
static NSString *currenciesKey = @"allCurrenciesKey";
static NSString *unlinkAddressName = @"Unlink";
static NSString *walletStatusKey = @"walletStatusKey";
static NSString *transactionsKey = @"transactionsKey";
static NSString *notificationsKey = @"notificationsKey";


const int kDefaultFeeInGroth = 10;
const int kFeeInGroth_Fork1 = 100;

const int kFeeInGroth_Unlink = 1100;
const int kFeeInGroth_MaxPrivacy = 1000100;

const std::map<Notification::Type,bool> activeNotifications {
    { Notification::Type::SoftwareUpdateAvailable, true },
    { Notification::Type::BeamNews, true },
    { Notification::Type::TransactionCompleted, true },
    { Notification::Type::TransactionFailed, true },
    { Notification::Type::AddressStatusChanged, false }
};

const bool isSecondCurrencyEnabled = true;
typedef void(^NewGenerateVaucherBlock)(ShieldedVoucherList v);

struct GenerateVaucherFunc
{
    NewGenerateVaucherBlock newGenerateVaucherBlock;

    void operator() (ShieldedVoucherList v){
        newGenerateVaucherBlock(v);
    }
};


typedef void(^GetMaxPrivacyLockBlock)(uint8_t limit);

struct GetMaxPrivacyLockFunc
{
    GetMaxPrivacyLockBlock block;
    
    void operator() (uint8_t limit){
        block(limit);
    }
};


@implementation AppModel  {
    BOOL isStarted;
    BOOL isRunning;
    
    NSString *localPassword;
    NSTimer *utxoTimer;
    
    int reconnectAttempts;
    NSMutableArray *reconnectNodes;

    Reachability *internetReachableFoo;
    
    IWalletDB::Ptr walletDb;
    WalletModel::Ptr wallet;
    Reactor::Ptr walletReactor;
    beam::wallet::TxParameters _txParameters;
    
    ECC::NoLeak<ECC::uintBig> passwordHash;
    
    NSString *pathLog;
    ByteBuffer lastVouchers;
    NSString *lastWalledId;
    std::string *lastWalledIdS;

    NSNumberFormatter *currencyFormatter;
}

+ (AppModel*_Nonnull)sharedManager {
    static AppModel *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

-(void)didGenerateVauchers:(ShieldedVoucherList) v {
    
}

-(id)init{
    self = [super init];
    
    [self createLogger];
        
    reconnectAttempts = 0;
    reconnectNodes = [NSMutableArray new];
    lastWalledId = @"";
    
    currencyFormatter = [[NSNumberFormatter alloc] init];
    currencyFormatter.currencyCode = @"";
    currencyFormatter.currencySymbol = @"";
    currencyFormatter.minimumFractionDigits = 0;
    currencyFormatter.maximumFractionDigits = 10;
    currencyFormatter.numberStyle = NSNumberFormatterCurrencyAccountingStyle;
    currencyFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    
    walletReactor = Reactor::create();
    io::Reactor::Scope s(*walletReactor); // do it in main thread
    
    _delegates = [NSPointerArray weakObjectsPointerArray];
    
    _transactions = [[NSMutableArray alloc] init];
    
    _shildedUtxos = [[NSMutableArray alloc] init];
    _contacts = [[NSMutableArray alloc] init];
    _notifications = [[NSMutableArray alloc] init];
    _presendedNotifications = [[NSMutableDictionary alloc] init];
    _deletedNotifications = [[NSMutableDictionary alloc] init];
    _preparedTransactions = [[NSMutableArray alloc] init];
    _preparedDeleteAddresses = [[NSMutableArray alloc] init];
    _preparedDeleteTransactions = [[NSMutableArray alloc] init];
    
    _currencies = [[NSMutableArray alloc] initWithArray:[self allCurrencies]];
    
    _isRestoreFlow = [[NSUserDefaults standardUserDefaults] boolForKey:restoreFlowKey];
    
    NSData *dataStatus = [[NSUserDefaults standardUserDefaults] objectForKey:walletStatusKey];
    if(dataStatus != nil) {
        _walletStatus = [NSKeyedUnarchiver unarchiveObjectWithData:dataStatus];
    }
    
    NSData *dataTransactions = [[NSUserDefaults standardUserDefaults] objectForKey:transactionsKey];
    if(dataTransactions != nil) {
        _transactions = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:dataTransactions]];
    }
    
    NSData *dataNotifications = [[NSUserDefaults standardUserDefaults] objectForKey:notificationsKey];
    if(dataNotifications != nil) {
        _notifications = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:dataNotifications]];
    }
    
    [self checkInternetConnection];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self loadRules];
    
    
    return self;
}


-(void)loadRules{
    if(Settings.sharedManager.target == Masternet) {
        Rules::get().pForks[1].m_Height = 10;
        Rules::get().pForks[2].m_Height = 20;
        Rules::get().MaxRollback = 10;
        Rules::get().CA.LockPeriod = 10;
        Rules::get().Shielded.m_ProofMax.n = 4;
        Rules::get().Shielded.m_ProofMax.M = 3;
        Rules::get().Shielded.m_ProofMin.n = 4;
        Rules::get().Shielded.m_ProofMin.M = 2;
        Rules::get().Shielded.MaxWindowBacklog = 150;
    }
    
    Rules::get().UpdateChecksum();
    LOG_INFO() << "Rules signature: " << Rules::get().get_SignatureStr();
}

+(NSString*_Nonnull)chooseRandomNodeWithoutNodes:(NSArray*)nodes {
    auto peers = getDefaultPeers();
    
    NSMutableArray *array = [NSMutableArray array];
    
    for (const auto& item : peers) {
        BOOL found = NO;
        NSString *address = [NSString stringWithUTF8String:item.c_str()];
        if ([address rangeOfString:@"shanghai"].location == NSNotFound) {
            for (NSString *node in nodes) {
                if([address isEqualToString:node]) {
                    found = YES;
                }
            }
            
            if (!found) {
                [array addObject:address];
            }
        }
    }
    
    
    if(array.count>0) {
        return array[0];
    }
    
    return @"";
}

+(NSArray*_Nonnull)randomNodes {
    auto peers = getDefaultPeers();
    
    NSMutableArray *array = [NSMutableArray array];
    
    for (const auto& item : peers) {
        NSString *address = [NSString stringWithUTF8String:item.c_str()];
        if([address rangeOfString:@"shanghai"].location == NSNotFound) {
            [array addObject:address];
        }
    }
    
    return array;
}

+(NSString*_Nonnull)chooseRandomNode {
    auto peers = getDefaultPeers();
    
    NSMutableArray *array = [NSMutableArray array];
    
    for (const auto& item : peers) {
        NSString *address = [NSString stringWithUTF8String:item.c_str()];
        if([address rangeOfString:@"shanghai"].location == NSNotFound) {
            [array addObject:address];
        }
    }
    
    srand([[NSDate date]  timeIntervalSince1970]);
    
    int inx = rand()%[array count];
    
    return [array objectAtIndex:inx];
}

-(void)setWalletAddresses:(NSMutableArray<BMAddress *> *)walletAddresses {
    _walletAddresses = [NSMutableArray arrayWithArray:walletAddresses];
}

-(void)setIsRestoreFlow:(BOOL)isRestoreFlow {
    _isRestoreFlow = isRestoreFlow;
    
    [[NSUserDefaults standardUserDefaults] setBool:_isRestoreFlow forKey:restoreFlowKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)changeTransactions {
    NSMutableArray *tr = [NSMutableArray arrayWithArray:self->_transactions];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:tr] forKey:transactionsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    });
}

-(void)changeNotifications {
    NSMutableArray *notif = [NSMutableArray arrayWithArray:self->_notifications];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:notif] forKey:notificationsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    });
}

#pragma mark - Status

-(void)setWalletStatus:(BMWalletStatus *)walletStatus {
    _walletStatus = walletStatus;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:self->_walletStatus] forKey:walletStatusKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Exchange

-(NSMutableArray<BMCurrency*>*_Nonnull)allCurrencies{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:currenciesKey]) {
        NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:currenciesKey];
        
        NSMutableArray *array = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
        
        return array;
    }
    
    return @[].mutableCopy;
}

-(void)saveCurrencies {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_currencies];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:currenciesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - Inetrnet

-(void)onOnline {
    if(self.connectionAfterOnlineTimer!=nil){
        [self.connectionAfterOnlineTimer invalidate];
        self.connectionAfterOnlineTimer = nil;
    }
    
    [[AppModel sharedManager] setIsInternetAvailable:YES];
    [[AppModel sharedManager] refreshAllInfo];
}

-(void)checkInternetConnection{
    __weak typeof(self) weakSelf = self;
    
    internetReachableFoo = [Reachability reachabilityWithHostName:@"www.google.com"];
    
    internetReachableFoo.reachableBlock = ^(Reachability*reach)
    {
        if (self->isRunning == NO && weakSelf.isLoggedin == YES) {
            self->isRunning = YES;
        }
        
        if (![[AppModel sharedManager] isInternetAvailable]) {
            
            if (weakSelf.isLoggedin == YES)
            {
                for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates) {
                    if ([delegate respondsToSelector:@selector(onNodeStartChanging)]) {
                        [delegate onNodeStartChanging];
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if([AppModel sharedManager].connectionAfterOnlineTimer==nil){
                        [AppModel sharedManager].connectionAfterOnlineTimer = [NSTimer scheduledTimerWithTimeInterval:3 target: [AppModel sharedManager] selector: @selector(onOnline) userInfo: nil repeats: NO];
                    }
                });
            }
            else{
                [[AppModel sharedManager] setIsInternetAvailable:YES];
            }
        }
    };
    
    internetReachableFoo.unreachableBlock = ^(Reachability*reach)
    {
        if(weakSelf.connectionAfterOnlineTimer!=nil){
            [weakSelf.connectionAfterOnlineTimer invalidate];
            weakSelf.connectionAfterOnlineTimer = nil;
        }
        
        [[AppModel sharedManager] setIsInternetAvailable:NO];
        [[AppModel sharedManager] setIsConnected:NO];
        
        for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
        {
            if ([delegate respondsToSelector:@selector(onNetwotkStatusChange:)]) {
                [delegate onNetwotkStatusChange:NO];
            }
            
            if ([delegate respondsToSelector:@selector(onNoInternetConnection)]) {
                [delegate onNoInternetConnection];
            }
        }
    };
    
    [internetReachableFoo startNotifier];
}

-(void)setIsConnected:(BOOL)isConnected {
    if(isConnected && _isConnected==NO && wallet!=nil){
        [self getWalletStatus];
        [self getUTXO];
    }
    _isConnected = isConnected;
}

-(void)setIsConnecting:(BOOL)isConnecting {
    _isConnecting = isConnecting;
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onNetwotkStartConnecting:)]) {
            [delegate onNetwotkStartConnecting:_isConnecting];
        }
    }
}

-(void)setIsNodeChanging:(BOOL)isNodeChanging {
    _isNodeChanging = isNodeChanging;
    
    if (_isNodeChanging) {
        [[AppModel sharedManager] startChangeNode];
    }
}

-(BOOL)reconnect {
    if(Settings.sharedManager.connectToRandomNode && reconnectAttempts < 3) {        
        [reconnectNodes addObject:Settings.sharedManager.nodeAddress];
        
       // reconnectAttempts = reconnectAttempts + 1;
        
        NSString *node = [AppModel chooseRandomNodeWithoutNodes:reconnectNodes];
        if(node.length > 0) {
            Settings.sharedManager.nodeAddress = node;
            [self changeNodeAddress];
            
            for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
            {
                if ([delegate respondsToSelector:@selector(onNetwotkStartReconnecting)]) {
                    [delegate onNetwotkStartReconnecting];
                }
            }
            
            return YES;
        }
    }
    return NO;
}


#pragma mark - Open, Create

-(BOOL)canRestoreWallet {
    //TODO: get node size. default 500 mb?
    if ([DiskStatusManager freeDiskspaceInMB] < 200) {
        return NO;
    }
    
    return YES;
}

-(BOOL)isWalletAlreadyAdded {
    return [[NSFileManager defaultManager] fileExistsAtPath:Settings.sharedManager.walletStoragePath];
}

-(BOOL)openWallet:(NSString*)pass {
    if (walletReactor == nil) {
        walletReactor = Reactor::create();
        io::Reactor::Scope s(*walletReactor); // do it in main thread
    }
    
    string dbFilePath = Settings.sharedManager.walletStoragePath.string;
    
    if (!walletDb) {
        try{
            walletDb = WalletDB::open(dbFilePath, pass.string);
        }
        catch (const std::exception& e) {
            return NO;
        }
        
        if (!walletDb){
            return NO;
        }
    }
    
    localPassword = [NSString stringWithString:pass];
    
    [self onWalledOpened:SecString(pass.string)];
    
    _categories = [[NSMutableArray alloc] initWithArray:[self allCategories]];
    
    return YES;
}

-(BOOL)canOpenWallet:(NSString*)pass {
    if (walletReactor == nil) {
        walletReactor = Reactor::create();
        io::Reactor::Scope s(*walletReactor); // do it in main thread
    }
    
    string dbFilePath = [Settings sharedManager].walletStoragePath.string;
    
    if (walletDb != nil) {
        return YES;
    }
    
    try{
        walletDb = WalletDB::open(dbFilePath, pass.string);
    }
    catch (const std::exception& e) {
        return NO;
    }
    
    if (!walletDb) {
        return NO;
    }
    
    return YES;
}

-(BOOL)isValidPassword:(NSString*_Nonnull)pass {
    auto hash = SecString(pass.string).hash();
    
    return hash.V == passwordHash.V;
}

-(BOOL)createWallet:(NSString*)phrase pass:(NSString*)pass {
    [self clearAllCategories];
    
    if (self.isInternetAvailable == NO) {
        return NO;
    }
    else if (walletDb != nil)
    {
        [self onWalledOpened:SecString(pass.string)];
        
        return YES;
    }
    
    string dbFilePath = [Settings sharedManager].walletStoragePath.string;
    
    //already created. restore wallet?
    if (WalletDB::isInitialized(dbFilePath)) {
        return NO;
    }
    
    //invalid parameters
    if ((phrase==nil || phrase.length==0) || (pass==nil || pass.length==0)) {
        return NO;
    }
    
    //convert string phrase to mnemonic WordList
    NSArray *wordsArray = [phrase componentsSeparatedByString:@";"];
    
    vector<string> wordList(wordsArray.count);
    
    for(int i=0; i<wordsArray.count; ++i){
        NSString *word = wordsArray[i];
        wordList[i] = word.string;
    }
    
    auto buf = decodeMnemonic(wordList);
    
    beam::SecString seed;
    seed.assign(buf.data(), buf.size());
    
    //create wallet db
    walletDb = WalletDB::init(dbFilePath, SecString(pass.string), seed.hash());
    
    if (!walletDb) {
        return NO;
    }
    
    walletReactor = Reactor::create();
    io::Reactor::Scope s(*walletReactor); // do it in main thread
    
    // generate default address
    WalletAddress address;
    walletDb->createAddress(address);
    address.m_label = "Default";
    walletDb->saveAddress(address);
    
    [self onWalledOpened:SecString(pass.string)];
    
    _categories = [[NSMutableArray alloc] initWithArray:[self allCategories]];
    
    return YES;
}

-(void)resetOnlyWallet {
    isStarted = NO;
    isRunning = NO;
    
    if (wallet!=nil){
        wallet.reset();
    }
    wallet = nil;
}

-(void)restartWallet {
    LOG_INFO() << "restart wallet";
    
    isStarted = NO;
    isRunning = NO;
    
    if (wallet!=nil){
        wallet.reset();
    }
    
    if (walletReactor!=nil){
        walletReactor.reset();
    }
    if (walletDb!=nil){
        walletDb.reset();
    }
    
    walletReactor = nil;
    wallet = nil;
    walletDb = nil;
    
    BOOL opened = [self canOpenWallet:localPassword];
    if (opened) {
        [self openWallet:localPassword];
    }
}


-(void)resetWallet:(BOOL)removeDatabase {
    if (self.isRestoreFlow) {
        self.isRestoreFlow = NO;
    }
    
    isStarted = NO;
    isRunning = NO;
    
    if (wallet!=nil){
        wallet.reset();
    }
    
    if (walletReactor!=nil){
        walletReactor.reset();
    }
    if (walletDb!=nil){
        walletDb.reset();
    }
    
    walletReactor = nil;
    wallet = nil;
    walletDb = nil;
    
    if(removeDatabase) {
        NSString *recoverPath = [[Settings sharedManager].walletStoragePath stringByAppendingString:@"_recover"];
        
        [[NSFileManager defaultManager] removeItemAtPath:[Settings sharedManager].walletStoragePath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:[Settings sharedManager].localNodeStorage error:nil];
        
        
    }
    
    _walletStatus = [BMWalletStatus new];
    [_transactions removeAllObjects];
    [_notifications removeAllObjects];

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:notificationsKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:transactionsKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:walletStatusKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[Settings sharedManager] resetNode];
}

-(void)startChangeWallet {
    NSString *oldPath = [Settings sharedManager].walletStoragePath;
    NSString *recoverPath = [[Settings sharedManager].walletStoragePath stringByAppendingString:@"_recover"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:recoverPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:recoverPath error:nil];
    }
    
    NSError *error;
    [[NSFileManager defaultManager] copyItemAtPath:oldPath toPath:recoverPath error:&error];
    
    if (error == nil) {
        [self resetWallet:YES];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:[Settings sharedManager].connectToRandomNode forKey:@"randomNodeKeyRecover"];
    [[NSUserDefaults standardUserDefaults] setObject:[Settings sharedManager].nodeAddress forKey:@"nodeKeyRecover"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.isRestoreFlow = YES;
}

-(void)stopChangeWallet {
    NSString *recoverPath = [[Settings sharedManager].walletStoragePath stringByAppendingString:@"_recover"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:recoverPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:recoverPath error:nil];
    }
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"randomNodeKeyRecover"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"nodeKeyRecover"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)startChangeNode {
    if(self.isInternetAvailable)
    {
        for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates) {
            if ([delegate respondsToSelector:@selector(onNodeStartChanging)]) {
                [delegate onNodeStartChanging];
            }
        }
    }
}

-(void)checkRecoveryWallet {
    NSString *oldPath = [Settings sharedManager].walletStoragePath;
    NSString *recoverPath = [[Settings sharedManager].walletStoragePath stringByAppendingString:@"_recover"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:recoverPath]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:oldPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:oldPath error:nil];
        }
        
        NSError *error;
        [[NSFileManager defaultManager] copyItemAtPath:recoverPath toPath:oldPath error:&error];
    }
    else if (_isRestoreFlow) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:oldPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:oldPath error:nil];
        }
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"nodeKeyRecover"]) {
        [Settings sharedManager].connectToRandomNode = [[NSUserDefaults standardUserDefaults] boolForKey:@"randomNodeKeyRecover"];
        [Settings sharedManager].nodeAddress = [[NSUserDefaults standardUserDefaults] objectForKey:@"nodeKeyRecover"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"randomNodeKeyRecover"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"nodeKeyRecover"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    self.isRestoreFlow = NO;
}

-(BOOL)isWalletInitialized{
    if (walletDb != nil && wallet != nil) {
        return YES;
    }
    
    return NO;
}

-(BOOL)isWalletRunning {
    if(wallet == nil) {
        return NO;
    }
    return isRunning;
}

-(void)onWalledOpened:(const SecString&) pass {
    passwordHash = pass.hash();
    
    if(!self.isRestoreFlow)
    {
        [self start];
    }
    else if(self.isRestoreFlow && self.restoreType == BMRestoreManual && [Settings sharedManager].isChangedNode) {
        [self start];
    }
}

-(void)restore:(NSString*_Nonnull)path{
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        string recoveryPath = path.string;
        
        RecoveryProgress prog;
        
        try{
            walletDb->ImportRecovery(recoveryPath, prog);
        }
        catch (const std::exception& e) {
            NSLog(@"ImportRecovery failed %s",e.what());
            
            NSString *erorString = [NSString stringWithUTF8String:e.what()];
            
            for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
            {
                if ([delegate respondsToSelector:@selector(onWalletError:)]) {
                    NSError *nativeError = [NSError errorWithDomain:@"beam"
                                                               code:NSUInteger(100)
                                                           userInfo:@{ NSLocalizedDescriptionKey:erorString }];
                    [delegate onWalletError:nativeError];
                }
            }
        }
        catch (...) {
            NSLog(@"ImportRecovery failed");
            
            NSString *erorString = @"Recovery failed";
            
            for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
            {
                if ([delegate respondsToSelector:@selector(onWalletError:)]) {
                    NSError *nativeError = [NSError errorWithDomain:@"beam"
                                                               code:NSUInteger(100)
                                                           userInfo:@{ NSLocalizedDescriptionKey:erorString }];
                    [delegate onWalletError:nativeError];
                }
            }
        }
    }
}

bool OnProgress(uint64_t done, uint64_t total) {
    return true;
}

-(void)start {
    if (isStarted == NO && walletDb != nil) {
        string nodeAddrStr = [Settings sharedManager].nodeAddress.string;
                
        auto additionalTxCreators = std::make_shared<std::unordered_map<TxType, BaseTransaction::Creator::Ptr>>();
        additionalTxCreators->emplace(TxType::UnlinkFunds, std::make_shared<lelantus::UnlinkFundsTransaction::Creator>());
        additionalTxCreators->emplace(TxType::PushTransaction, std::make_shared<lelantus::PushTransaction::Creator>(walletDb));
        additionalTxCreators->emplace(TxType::PullTransaction, std::make_shared<lelantus::PullTransaction::Creator>());
        
        wallet = make_shared<WalletModel>(walletDb, nodeAddrStr, walletReactor);
        wallet->getAsync()->setNodeAddress(nodeAddrStr);
        wallet->start(activeNotifications, isSecondCurrencyEnabled, additionalTxCreators);
        
        isRunning = YES;
        isStarted = YES;
    }
    else if(self.isConnected && isStarted && walletDb != nil && self.isInternetAvailable) {
        for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
        {
            if ([delegate respondsToSelector:@selector(onSyncProgressUpdated: total:)]) {
                [delegate onSyncProgressUpdated:0 total:0];
            }
        }
    }
    else if(wallet != nil)
    {
        if(self.isInternetAvailable && isRunning == NO && ![[Settings sharedManager] isLocalNode])
        {
            isRunning = YES;
            
            auto additionalTxCreators = std::make_shared<std::unordered_map<TxType, BaseTransaction::Creator::Ptr>>();
            additionalTxCreators->emplace(TxType::UnlinkFunds, std::make_shared<lelantus::UnlinkFundsTransaction::Creator>());
            additionalTxCreators->emplace(TxType::PushTransaction, std::make_shared<lelantus::PushTransaction::Creator>(walletDb));
            additionalTxCreators->emplace(TxType::PullTransaction, std::make_shared<lelantus::PullTransaction::Creator>());
            
            wallet->start(activeNotifications, isSecondCurrencyEnabled, additionalTxCreators);
        }
    }
}

-(void)changePassword:(NSString*_Nonnull)pass {
    auto password = SecString(pass.string);
    
    passwordHash = password.hash();
    
    wallet->getAsync()->changeWalletPassword(password);
}

-(void)changeNodeAddress {
    if (wallet != nil) {
        self.isNodeChanging = YES;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            string nodeAddrStr = [Settings sharedManager].nodeAddress.string;
            self->wallet->getAsync()->setNodeAddress(nodeAddrStr);
        });
    }
}

-(BOOL)isMyAddress:(NSString*_Nullable)address {
    if ([self isToken:address])
    {
        BMTransactionParameters *params = [self getTransactionParameters:address];
        address = params.address;
    }
    
    for (BMAddress *add in _walletAddresses) {
        if ([add.walletId isEqualToString:address]) {
            return YES;
        }
    }
    
    return NO;
}

-(BOOL)isValidNodeAddress:(NSString*_Nonnull)string {
    NSString *port = [string componentsSeparatedByString:@":"].lastObject;
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *myNumber = [formatter numberFromString:port];
    
    if (myNumber == nil) {
        return NO;
    }
    else if (port.length < 2 || ([port isEqualToString:string])) {
        return NO;
    }
    
    Address nodeAddr;
    BOOL isValid =  nodeAddr.resolve(string.string.c_str());
    return isValid;
}

-(void)exportOwnerKey:(NSString*_Nonnull)password result:(ExportOwnerKey _Nonnull)block{
    if(self->wallet == nil) {
        [self start];
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        auto pass = SecString(password.string);
        
        const auto& ownerKey = self->wallet->exportOwnerKey(pass);
        
        NSString *exportedKey = [NSString stringWithUTF8String:ownerKey.c_str()];
        dispatch_async(dispatch_get_main_queue(), ^{
            block(exportedKey);
        });
    });
}

#pragma mark - Updates

-(void)getWalletStatus {
    if (wallet != nil)  {
        wallet->getAsync()->getWalletStatus();
        wallet->getAsync()->getTransactions();
        wallet->getAsync()->getAddresses(false);
        wallet->getAsync()->getAddresses(true);
        wallet->getAsync()->getExchangeRates();
        wallet->getAsync()->getNotifications();
        
        auto func = GetMaxPrivacyLockFunc();
        func.block = ^(uint8_t lock) {
            [Settings sharedManager].lockMaxPrivacyValue = lock;
        };
        
        wallet->getAsync()->getMaxPrivacyLockTimeLimitHours(func);
    }
}

-(void)getWalletNotifications {
    wallet->getAsync()->getNotifications();
}

-(void)getNetworkStatus {
    if (wallet != nil)  {
        wallet->getAsync()->getNetworkStatus();
    }
}

-(void)refreshAllInfo{
    [internetReachableFoo stopNotifier];
    [internetReachableFoo startNotifier];
    
    if (wallet != nil) {
        if (self.isConnected)
        {
            [self setIsConnecting:YES];
        }
        
        [self getNetworkStatus];
        
        if (self.isConnected)
        {
            [self getWalletStatus];
        }
    }
}

-(void)didBecomeActiveNotification{
    if([AppModel sharedManager].isLoggedin)
    {
        [self refreshAllInfo];
    }
}

#pragma mark - Token

-(BOOL)isToken:(NSString*_Nullable)address {
    if (address==nil) {
        return NO;
    }
    auto params = beam::wallet::ParseParameters(address.string);
    return params && params->GetParameter<beam::wallet::TxType>(beam::wallet::TxParameterID::TransactionType);
}

//-(BMAddress*_Nonnull)generateAddress {
//    WalletAddress address = GenerateNewAddress(walletDb, "", WalletAddress::ExpirationStatus::OneDay);
//
//    BMAddress *bmAddress = [[BMAddress alloc] init];
//    bmAddress.duration = address.m_duration;
//    bmAddress.ownerId = address.m_OwnID;
//    bmAddress.createTime = address.m_createTime;
//    bmAddress.categories = [NSMutableArray new];
//    bmAddress.label = [NSString stringWithUTF8String:address.m_label.c_str()];
//    bmAddress.walletId = [NSString stringWithUTF8String:to_string(address.m_walletID).c_str()];
//    bmAddress.identity = [NSString stringWithUTF8String:to_string(address.m_Identity).c_str()];
//    bmAddress.token = [self token:NO nonInteractive:NO isPermanentAddress:NO amount:0 walleetId:bmAddress.walletId identity:bmAddress.identity ownId:bmAddress.ownerId];
//
//    return bmAddress;
//}

-(BMAddress*_Nonnull)generateWithdrawAddress {
    for (int i=0; i<_walletAddresses.count; i++) {
        if ([_walletAddresses[i].label isEqualToString:@"Beam Runner"]
            && _walletAddresses[i].duration == 0
            && !_walletAddresses[i].isExpired) {
            return _walletAddresses[i];
        }
    }
    
    WalletAddress address = GenerateNewAddress(walletDb, "Beam Runner", WalletAddress::ExpirationStatus::Never);
    
    BMAddress *bmAddress = [[BMAddress alloc] init];
    bmAddress.duration = address.m_duration;
    bmAddress.ownerId = address.m_OwnID;
    bmAddress.createTime = address.m_createTime;
    bmAddress.categories = [NSMutableArray new];
    bmAddress.label = [NSString stringWithUTF8String:address.m_label.c_str()];
    bmAddress.walletId = [NSString stringWithUTF8String:to_string(address.m_walletID).c_str()];
    bmAddress.identity = [NSString stringWithUTF8String:to_string(address.m_Identity).c_str()];
    bmAddress.address = [NSString stringWithUTF8String:(address.m_Address).c_str()];

   // bmAddress.token = [self token:NO nonInteractive:NO isPermanentAddress:NO amount:0 walleetId:bmAddress.walletId identity:bmAddress.identity ownId:bmAddress.ownerId];
    
    return bmAddress;
}


-(NSString*_Nonnull)generateOfflineAddress:(NSString*_Nonnull)walleetId amount:(double)amount {
    
    uint64_t bAmount = round(amount * Rules::Coin);

    auto address = walletDb->getAddress(walleetId.string);
    
    if(![lastWalledId isEqualToString:walleetId]) {
        lastWalledId = walleetId;
        lastVouchers = wallet->generateVouchers(address->m_OwnID, 10);
    }

    TxParameters offlineParameters;
    offlineParameters.SetParameter(TxParameterID::TransactionType, beam::wallet::TxType::PushTransaction);
    offlineParameters.SetParameter(TxParameterID::ShieldedVoucherList, lastVouchers);
    offlineParameters.SetParameter(TxParameterID::PeerID, address->m_walletID);
    offlineParameters.SetParameter(TxParameterID::PeerWalletIdentity, address->m_Identity);
    offlineParameters.SetParameter(TxParameterID::PeerOwnID, address->m_OwnID);
    offlineParameters.SetParameter(TxParameterID::IsPermanentPeerID, true);
    if (bAmount > 0)
    {
        offlineParameters.SetParameter(TxParameterID::Amount, bAmount);
    }
    auto token = to_string(offlineParameters);
    return [NSString stringWithUTF8String:token.c_str()];
}

-(NSString*_Nonnull)generateRegularAddress:(NSString*_Nonnull)walleetId amount:(double)amount isPermanentAddress:(BOOL)isPermanentAddress {
    uint64_t bAmount = round(amount * Rules::Coin);
        
    auto address = walletDb->getAddress(walleetId.string);
    
    TxParameters params;
    params.SetParameter(TxParameterID::LibraryVersion, std::string(BEAM_LIB_VERSION));
    if (bAmount > 0) {
        params.SetParameter(TxParameterID::Amount, bAmount);
    }
    params.SetParameter(TxParameterID::PeerID, address->m_walletID);
    params.SetParameter(TxParameterID::PeerWalletIdentity, address->m_Identity);
    params.SetParameter(TxParameterID::IsPermanentPeerID, isPermanentAddress);
    params.SetParameter(TxParameterID::TransactionType, TxType::Simple);
    params.DeleteParameter(TxParameterID::Voucher);
    
    auto token = to_string(params);
    return [NSString stringWithUTF8String:token.c_str()];
}


-(void)generateMaxPrivacyAddress:(NSString*_Nonnull)walleetId amount:(double)amount result:(PublicAddressBlock _Nonnull)block {
    uint64_t bAmount = round(amount * Rules::Coin);
    
    auto address = walletDb->getAddress(walleetId.string);
    
    auto func = GenerateVaucherFunc();
    func.newGenerateVaucherBlock = ^(ShieldedVoucherList list) {
        auto token = beam::wallet::GenerateMaxPrivacyAddress(*address, bAmount, list[0], std::string(BEAM_LIB_VERSION));
        block([NSString stringWithUTF8String:token.c_str()]);
    };
    
    wallet->getAsync()->generateVouchers(address->m_OwnID, 1, func);
}

-(NSString*_Nonnull)token:(BOOL)maxPrivacy nonInteractive:(BOOL)nonInteractive isPermanentAddress:(BOOL)isPermanentAddress amount:(double)amount walleetId:(NSString*_Nonnull)walleetId identity:(NSString*_Nonnull)identity ownId:(int64_t)ownId {
    
    WalletID m_walletID(Zero);
    m_walletID.FromHex(walleetId.string);
        
    bool isValid = false;
    auto buf = from_hex(identity.string, &isValid);
    PeerID m_Identity = Blob(buf);
        
    TxParameters params;
    params.SetParameter(TxParameterID::PeerID, m_walletID);
    params.SetParameter(TxParameterID::PeerWalletIdentity, m_Identity);
    params.SetParameter(TxParameterID::IsPermanentPeerID, isPermanentAddress);

    if (amount > 0) {
        uint64_t bAmount = round(amount * Rules::Coin);
        params.SetParameter(TxParameterID::Amount, bAmount);
    }
    
    if (maxPrivacy) {
        params.SetParameter(TxParameterID::TransactionType, beam::wallet::TxType::PushTransaction);
    }
    else {
        params.SetParameter(TxParameterID::TransactionType, beam::wallet::TxType::Simple);
    }
    
    if(nonInteractive) {
        auto vouchers = wallet->generateVouchers(ownId, 10);
        if (!vouchers.empty())
        {
            params.SetParameter(TxParameterID::ShieldedVoucherList, vouchers);
        }
    }
    
    params.SetParameter(TxParameterID::LibraryVersion, std::string(BEAM_LIB_VERSION));

    auto token = to_string(params);
    return [NSString stringWithUTF8String:token.c_str()];
}


#pragma mark - Addresses

-(BOOL)isAddress:(NSString*_Nullable)address {
    if (address==nil) {
        return NO;
    }
    return beam::wallet::CheckReceiverAddress(address.string);
}

-(void)refreshAddressesFrom{
    if (wallet != nil)  {
        self.walletAddresses = [self getWalletAddresses];
        self.contacts = [self getWalletContacts];
    }
}

-(void)refreshAddresses{
    if (wallet != nil)  {
        if (self.isConnected) {
            self.walletAddresses = [self getWalletAddresses];
            self.contacts = [self getWalletContacts];
        }
    }
}

-(BOOL)isExpiredAddress:(NSString*_Nullable)address {
    if (address!=nil) {
        if(address.length)
        {
            WalletID walletID(Zero);
            if (walletID.FromHex(address.string))
            {
                try{
                    auto receiverAddr = walletDb->getAddress(walletID);
                    
                    if(receiverAddr) {
                        if (receiverAddr->m_OwnID && receiverAddr->isExpired())
                        {
                            return YES;
                        }
                    }
                }
                catch (const std::exception& e) {
                    return NO;
                }
                catch (...) {
                    return NO;
                }
            }
        }
    }
    
    return NO;
}

-(BOOL)isValidAddress:(NSString*_Nullable)address {
    if (address==nil) {
        return NO;
    }
    
    if (address.length < 15) {
        return NO;
    }
    
    return [self isAddress:address] || [self isToken:address];
}

-(void)editBotAddress:(NSString*_Nonnull)address {
    try{
        WalletID walletID(Zero);
        if (walletID.FromHex(address.string))
        {
            std::vector<WalletAddress> addresses = wallet->ownAddresses;
            
            for (int i=0; i<addresses.size(); i++)
            {
                NSString *wAddress = [NSString stringWithUTF8String:to_string(addresses[i].m_walletID).c_str()];
                
                if ([wAddress isEqualToString:address])
                {
                    wallet->getAsync()->updateAddress(walletID, "telegram bot", WalletAddress::ExpirationStatus::Never);
                    
                    break;
                }
            }
        }
    }
    catch (const std::exception& e) {
        NSLog(@"error edit bot address");
    }
    catch (...) {
        NSLog(@"error edit bot address");
    }
}

-(void)setExpires:(int)hours toAddress:(NSString*)address {
    WalletID walletID(Zero);
    if (walletID.FromHex(address.string))
    {
        std::vector<WalletAddress> addresses = wallet->ownAddresses;
        
        for (int i=0; i<addresses.size(); i++)
        {
            NSString *wAddress = [NSString stringWithUTF8String:to_string(addresses[i].m_walletID).c_str()];
            
            if ([wAddress isEqualToString:address])
            {
                
                try{
                    wallet->getAsync()->updateAddress(walletID, addresses[i].m_label, hours == 0 ? WalletAddress::ExpirationStatus::Never : WalletAddress::ExpirationStatus::OneDay);
                }
                catch (const std::exception& e) {
                    NSLog(@"setExpires failed");
                }
                catch (...) {
                    NSLog(@"setExpires failed");
                }
                
                break;
            }
        }
    }
}


-(void)setWalletCategories:(NSMutableArray<NSString*>*_Nonnull)categories toAddress:(NSString*_Nonnull)address {
    WalletID walletID(Zero);
    
    if (walletID.FromHex(address.string))
    {
        std::vector<WalletAddress> addresses = wallet->ownAddresses;
        
        NSString *_categories = [categories componentsJoinedByString:@","];
        
        for (int i=0; i<addresses.size(); i++)
        {
            NSString *wAddress = [NSString stringWithUTF8String:to_string(addresses[i].m_walletID).c_str()];
            
            NSString *wCategory = [NSString stringWithUTF8String:addresses[i].m_category.c_str()];
            
            if ([wAddress isEqualToString:address] && ![wCategory isEqualToString:_categories])
            {
                addresses[i].m_category = _categories.string;
                
                wallet->getAsync()->saveAddress(addresses[i], true);
                
                break;
            }
        }
    }
}

-(void)setContactComment:(NSString*)comment toAddress:(NSString*_Nonnull)address {
    WalletID walletID(Zero);
    if (walletID.FromHex(address.string))
    {
        std::vector<WalletAddress> addresses = wallet->contacts;
        
        for (int i=0; i<addresses.size(); i++)
        {
            NSString *wAddress = [NSString stringWithUTF8String:to_string(addresses[i].m_walletID).c_str()];
            
            if ([wAddress isEqualToString:address])
            {
                WalletAddress _address;
                _address.m_label = comment.string;
                _address.m_category = addresses[i].m_category;
                _address.m_walletID = walletID;
                _address.m_createTime = NSDate.date.timeIntervalSince1970;
                _address.m_Identity = addresses[i].m_Identity;

                try{
                    wallet->getAsync()->saveAddress(_address, false);
                }
                catch (const std::exception& e) {
                    NSLog(@"setExpires failed");
                }
                catch (...) {
                    NSLog(@"setExpires failed");
                }
                
                break;
            }
        }
    }
}

-(void)setWalletComment:(NSString*)comment toAddress:(NSString*_Nonnull)address {
    WalletID walletID(Zero);
    if (walletID.FromHex(address.string))
    {
        std::vector<WalletAddress> addresses = wallet->ownAddresses;
        
        for (int i=0; i<addresses.size(); i++)
        {
            NSString *wAddress = [NSString stringWithUTF8String:to_string(addresses[i].m_walletID).c_str()];
            
            if ([wAddress isEqualToString:address])
            {
                try{
                    wallet->getAsync()->updateAddress(walletID, comment.string, addresses[i].m_duration == 0 ? WalletAddress::ExpirationStatus::Never : WalletAddress::ExpirationStatus::OneDay);
                }
                catch (const std::exception& e) {
                    NSLog(@"setExpires failed");
                }
                catch (...) {
                    NSLog(@"setExpires failed");
                }
                
                break;
            }
        }
    }
}

-(void)deleteAddress:(NSString*_Nullable)address {
    WalletID walletID(Zero);
    if (walletID.FromHex(address.string))
    {
        wallet->getAsync()->deleteAddress(walletID);
        
        NSString *notificationId = [self getNotificationByObject:address];
        if (notificationId!=nil) {
            [self deleteNotification:notificationId];
        }
    }
    else {
        wallet->getAsync()->deleteAddress(address.string);	
    }
}

-(void)cancelDeleteAddress:(NSString*_Nonnull)address {
    BOOL isNeedRequestTransactions = NO;
    
    for (int i=0; i<_preparedDeleteAddresses.count; i++) {
        if ([_preparedDeleteAddresses[i].walletId isEqualToString:address]) {
            
            if (_preparedDeleteAddresses[i].isNeedRemoveTransactions) {
                isNeedRequestTransactions = YES;
                [_preparedDeleteTransactions removeAllObjects];
            }
            
            [_preparedDeleteAddresses removeObjectAtIndex:i];
            
            break;
        }
    }
    wallet->getAsync()->getAddresses(true);
    wallet->getAsync()->getAddresses(false);
    
    if (isNeedRequestTransactions) {
        wallet->getAsync()->getWalletStatus();
        wallet->getAsync()->getTransactions();
    }
}

-(void)deletePreparedAddresses:(NSString*_Nonnull)address {
    for (int i=0; i<_preparedDeleteAddresses.count; i++) {
        if ([_preparedDeleteAddresses[i].walletId isEqualToString:address]) {
            if (_preparedDeleteAddresses[i].isNeedRemoveTransactions) {
                NSMutableArray *transactions = [[AppModel sharedManager] getPreparedTransactionsFromAddress:_preparedDeleteAddresses[i]];
                
                [_preparedDeleteTransactions removeAllObjects];
                
                for (BMTransaction *tr in transactions) {
                    [[AppModel sharedManager] deleteTransaction:tr.ID];
                }
            }
            
            [[AppModel sharedManager] deleteAddress:_preparedDeleteAddresses[i].walletId];
            
            [_preparedDeleteAddresses removeObjectAtIndex:i];
            
            break;
        }
    }
}

-(void)prepareDeleteAddress:(BMAddress*_Nonnull)address
         removeTransactions:(BOOL)removeTransactions {
    
    address.isNeedRemoveTransactions = removeTransactions;
    
    if (removeTransactions)
    {
        NSMutableArray <BMTransaction*>*transactions = [[AppModel sharedManager] getCompletedTransactionsFromAddress:address];
        
        NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
        
        for (int i=0; i<transactions.count; i++) {
            NSString *id1 = transactions[i].ID;
            
            for (int j=0; j<_transactions.count; j++) {
                NSString *id2 = _transactions[j].ID;
                
                if ([id1 isEqualToString:id2]) {
                    [set addIndex:j];
                }
            }
        }
        
        [_preparedDeleteTransactions addObjectsFromArray:transactions];
        
        [_transactions removeObjectsAtIndexes:set];
        
        for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
        {
            if ([delegate respondsToSelector:@selector(onReceivedTransactions:)]) {
                [delegate onReceivedTransactions:_transactions];
            }
        }
    }
    
    for (int i=0; i<_walletAddresses.count; i++) {
        if ([_walletAddresses[i].walletId isEqualToString:address.walletId]) {
            [_walletAddresses removeObjectAtIndex:i];
            break;
        }
    }
    
    for (int i=0; i<_contacts.count; i++) {
        if ([_contacts[i].address.walletId isEqualToString:address.walletId]) {
            [_contacts removeObjectAtIndex:i];
            [address setIsContact:YES];
            break;
        }
    }
    
    [_preparedDeleteAddresses addObject:address];
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onWalletAddresses:)]) {
            [delegate onWalletAddresses:_walletAddresses];
        }
    }
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onAddedDeleteAddress:)]) {
            [delegate onAddedDeleteAddress:address];
        }
    }
}

-(NSString*_Nonnull)getTransactionComment:(NSString*_Nonnull)address {
    NSMutableArray *array = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults]objectForKey:transactionCommentsKey]];
    
    for (NSDictionary *dict in array) {
        if ([dict objectForKey:address]) {
            return [dict objectForKey:address];
        }
    }
    
    return @"";
}

-(void)setTransactionComment:(NSString*_Nonnull)address comment:(NSString*_Nonnull)comment {
    NSMutableArray *array = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults]objectForKey:transactionCommentsKey]];
    
    if(comment.length > 0)
    {
        for (int i=0; i<array.count; i++)
        {
            if ([array[i] objectForKey:address]) {
                [array removeObjectAtIndex:i];
                break;
            }
        }
        
        [array addObject:@{address:comment}];
        [[NSUserDefaults standardUserDefaults] setObject:array forKey:transactionCommentsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


-(void)generateNewWalletAddress {
    if (wallet!=nil) {
        wallet->getAsync()->generateNewAddress();
    }
}

-(void)generateNewWalletAddressWithBlock:(NewAddressGeneratedBlock _Nonnull )block{
    self.generatedNewAddressBlock = block;
    
    if (wallet!=nil) {
        wallet->getAsync()->generateNewAddress();
    }
}

-(void)getPublicAddress:(PublicAddressBlock _Nonnull )block {
    self.getPublicAddressBlock = block;
    wallet->getAsync()->getPublicAddress();
}

-(NSMutableArray<BMContact*>*_Nonnull)getWalletContacts {
    std::vector<WalletAddress> addrs = walletDb->getAddresses(false);
    
    wallet->contacts.clear();
    
    for (int i=0; i<addrs.size(); i++)
        wallet->contacts.push_back(addrs[i]);
    
    NSMutableArray *contacts = [[NSMutableArray alloc] init];
    
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
        address.address = [NSString stringWithUTF8String:(walletAddr.m_Address).c_str()];

        BMContact *contact = [[BMContact alloc] init];
        contact.address = address;
        contact.name = address.label;
        
        [contacts addObject:contact];
    }
    
    return contacts;
}

-(NSMutableArray<BMAddress*>*_Nonnull)getWalletAddresses {
    std::vector<WalletAddress> addrs = walletDb->getAddresses(true);
    
    wallet->ownAddresses.clear();
    
    for (int i=0; i<addrs.size(); i++)
        wallet->ownAddresses.push_back(addrs[i]);
    
    NSMutableArray *addresses = [[NSMutableArray alloc] init];
    
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
        address.walletId = [NSString stringWithUTF8String:to_string(walletAddr.m_walletID).c_str()];
        address.address = [NSString stringWithUTF8String:(walletAddr.m_Address).c_str()];

        if([address.label isEqualToString:@"Default"])
        {
            address.label = [@"default" localized];
        }
        [addresses addObject:address];
    }
    
    return addresses;
}

-(NSMutableArray<BMTransaction*>*_Nonnull)getPreparedTransactionsFromAddress:(BMAddress*_Nonnull)address {
    
    NSMutableArray *result = [NSMutableArray array];
    for (BMTransaction *tr in _preparedDeleteTransactions)
    {
        if ([tr.senderAddress isEqualToString:address.walletId]
            || [tr.receiverAddress isEqualToString:address.walletId]
            || [tr.token isEqualToString:address.walletId]) {
            [result addObject:tr];
        }
    }
    
    return result;
}

-(NSMutableArray<BMTransaction*>*_Nonnull)getTransactionsFromAddress:(BMAddress*_Nonnull)address {
    
    NSMutableArray *result = [NSMutableArray array];
    NSArray * array = [NSArray arrayWithArray:self.transactions];
    
    for (BMTransaction *tr in array)
    {
        if ([tr.senderAddress isEqualToString:address.walletId]
            || [tr.receiverAddress isEqualToString:address.walletId]
            || [tr.token isEqualToString:address.walletId]) {
            [result addObject:tr];
        }
    }
    
    return result;
}


-(NSMutableArray<BMTransaction*>*_Nonnull)getCompletedTransactionsFromAddress:(BMAddress*_Nonnull)address {
    
    NSMutableArray *result = [NSMutableArray array];
    for (BMTransaction *tr in self.transactions.reverseObjectEnumerator)
    {
        if ([tr.senderAddress isEqualToString:address.walletId]
            || [tr.receiverAddress isEqualToString:address.walletId]
            || [tr.token isEqualToString:address.walletId]) {
            if (tr.enumStatus == BMTransactionStatusCancelled || tr.enumStatus == BMTransactionStatusCompleted || tr.enumStatus == BMTransactionStatusFailed)
            {
                [result addObject:tr];
            }
        }
    }
    
    return result;
}

-(void)editCategoryAddress:(BMAddress*_Nonnull)address {
    BMContact *contact = [self getContactFromId:address.walletId];
    if(contact != nil)
    {
        WalletID walletID(Zero);
        if (walletID.FromHex(address.walletId.string))
        {
            bool isValid = false;
            auto buf = from_hex(contact.address.identity.string, &isValid);
            PeerID m_Identity = Blob(buf);
            
            WalletAddress _address;
            _address.m_label = address.label.string;
            _address.m_category = [address.categories componentsJoinedByString:@","].string;
            _address.m_walletID = walletID;
            _address.m_createTime = NSDate.date.timeIntervalSince1970;
            _address.m_Identity = m_Identity;
            walletDb->saveAddress(_address);
        }
    }
    else{
        WalletID walletID(Zero);
        if (walletID.FromHex(address.walletId.string)){
            std::vector<WalletAddress> addresses = wallet->ownAddresses;
            for (int i=0; i<addresses.size(); i++){
                NSString *wAddress = [NSString stringWithUTF8String:to_string(addresses[i].m_walletID).c_str()];
                NSString *wCategory = [NSString stringWithUTF8String:addresses[i].m_category.c_str()];
                if ([wAddress isEqualToString:address.walletId] && ![wCategory isEqualToString:[address.categories componentsJoinedByString:@","]]){
                    addresses[i].m_category = [address.categories componentsJoinedByString:@","].string;
                    wallet->getAsync()->saveAddress(addresses[i], true);
                    break;
                }
            }
        }
    }
}

-(void)editAddress:(BMAddress*_Nonnull)address {
    BMContact *contact = [self getContactFromId:address.walletId];
    
    if(contact != nil)
    {
        WalletID walletID(Zero);
        if (walletID.FromHex(address.walletId.string))
        {
            bool isValid = false;
            auto buf = from_hex(contact.address.identity.string, &isValid);
            PeerID m_Identity = Blob(buf);
            
            WalletAddress _address;
            _address.m_label = address.label.string;
            _address.m_category = [address.categories componentsJoinedByString:@","].string;
            _address.m_walletID = walletID;
            _address.m_Identity = m_Identity;
            _address.m_createTime = NSDate.date.timeIntervalSince1970;
            walletDb->saveAddress(_address);
        }
        else {
            [self addContact:@"" address:address.address name:address.label categories:address.categories identidy:address.identity];
        }
    }
    else{
        WalletID walletID(Zero);
        if (walletID.FromHex(address.walletId.string))
        {
            [_presendedNotifications setValue:address.walletId forKey:address.walletId];
            
            std::vector<WalletAddress> addresses = wallet->ownAddresses;
            
            for (int i=0; i<addresses.size(); i++)
            {
                NSString *wAddress = [NSString stringWithUTF8String:to_string(addresses[i].m_walletID).c_str()];
                
                NSString *wCategory = [NSString stringWithUTF8String:addresses[i].m_category.c_str()];
                
                if ([wAddress isEqualToString:address.walletId])
                {
                    addresses[i].m_category = [address.categories componentsJoinedByString:@","].string;
                    addresses[i].m_label = address.label.string;
                    
                    if(address.isNowExpired) {
                        addresses[i].setExpiration(beam::wallet::WalletAddress::ExpirationStatus::Expired);
                    }
                    else if(address.isNowActive) {
                        if (address.isNowActiveDuration == 0){
                            addresses[i].setExpiration(beam::wallet::WalletAddress::ExpirationStatus::Never);
                        }
                        else{
                            addresses[i].setExpiration(beam::wallet::WalletAddress::ExpirationStatus::OneDay);
                        }
                    }
                    else{
                        if (address.isExpired) {
                            [_deletedNotifications setObject:wAddress forKey:wAddress];
                            addresses[i].setExpiration(beam::wallet::WalletAddress::ExpirationStatus::Expired);
                        }
                        else  {
                            if (address.duration == 0) {
                                addresses[i].setExpiration(beam::wallet::WalletAddress::ExpirationStatus::Never);
                            }
                            else {
                                addresses[i].setExpiration(beam::wallet::WalletAddress::ExpirationStatus::AsIs);
                            }
                        }
                    }
                    
//                    NSString *s = [NSString stringWithUTF8String:to_string(addresses[i].m_Identity).c_str()];
                    
                    wallet->getAsync()->saveAddress(addresses[i], true);
                    
                    break;
                }
            }
        }
    }
}

-(void)clearAllAddresses{
    for (BMAddress *add in _walletAddresses) {
        [self deleteAddress:add.walletId];
    }
}

-(NSString*_Nonnull)generateQRCodeString:(NSString*_Nonnull)address amount:(NSString*_Nullable)amount {
    
    NSString *qrString = [NSString stringWithFormat:@"beam:%@",address];
    if (amount!=nil && ![self isToken:address]) {
        NSString *trimmed = [amount stringByReplacingOccurrencesOfString:@"," withString:@"."];
        if (trimmed.doubleValue > 0) {
            qrString = [qrString stringByAppendingString:[NSString stringWithFormat:@"?amount=%@",trimmed]];
        }
    }
    
    return  qrString;
}

-(void)addContact:(NSString*_Nonnull)addressId address:(NSString*_Nullable)address name:(NSString*_Nonnull)name categories:(NSArray*_Nonnull)categories identidy:(NSString*_Nullable)identidy{

    if(address != nil) {
        bool isValid = false;
        auto buf = from_hex(identidy.string, &isValid);
        PeerID m_Identity = Blob(buf);
        
        WalletAddress savedAddress;
        savedAddress.m_walletID = Zero;
        savedAddress.m_createTime = getTimestamp();
        savedAddress.m_Identity = m_Identity;
        savedAddress.m_label = name.string;
        savedAddress.m_duration = WalletAddress::AddressExpirationNever;
        savedAddress.m_Address = address.string;
        savedAddress.m_category =  [categories componentsJoinedByString:@","].string;
        wallet->getAsync()->saveAddress(savedAddress, false);
    }
    else {
        WalletID walletID(Zero);
        if (walletID.FromHex(addressId.string))
        {
            WalletAddress savedAddress;
            savedAddress.m_label = name.string;
            savedAddress.m_category = [categories componentsJoinedByString:@","].string;
            savedAddress.m_walletID = walletID;
            if (identidy!=nil) {
                bool isValid = false;
                auto buf = from_hex(identidy.string, &isValid);
                PeerID m_Identity = Blob(buf);
                savedAddress.m_Identity = m_Identity;
                if(address != nil) {
                    savedAddress.m_Address = address.string;
                }
            }
            savedAddress.m_createTime = NSDate.date.timeIntervalSince1970;
            walletDb->saveAddress(savedAddress);
        }
    }
}

-(BMAddress*_Nullable)findAddressByName:(NSString*_Nonnull)name {
    for (BMAddress *add in _walletAddresses.reverseObjectEnumerator) {
        if ([add.label isEqualToString:name]) {
            return add;
        }
    }
    return nil;
}

-(BMAddress*_Nullable)findAddressByID:(NSString*_Nonnull)ID {
    for (BMAddress *add in _walletAddresses.reverseObjectEnumerator) {
        if ([add.walletId isEqualToString:ID]) {
            return add;
        }
    }
    
    for (BMContact *contact in _contacts.reverseObjectEnumerator) {
        if ([contact.address.walletId isEqualToString:ID]) {
            return contact.address;
        }
    }
    
    return nil;
}

#pragma mark - Delegates

- (NSUInteger)indexOfDelegate:(id)delegate {
    for (NSUInteger i = 0; i < _delegates.count; i ++) {
        if ([_delegates pointerAtIndex:i] == (__bridge void *)(delegate)) {
            return i;
        }
    }
    return NSNotFound;
}

-(void)addDelegate:(id<WalletModelDelegate>_Nullable) delegate {
    [_delegates compact];
    
    void * objPtr = (__bridge void *)delegate;
    [_delegates addPointer:objPtr];
}

-(void)removeDelegate:(id<WalletModelDelegate>_Nullable) delegate {
    [_delegates compact];
    
    void * objPtr = (__bridge void *)delegate;
    
    for(NSUInteger i = 0; i < _delegates.count; i++) {
        void * ptr = [_delegates pointerAtIndex:i];
        if (ptr == objPtr) {
            [_delegates removePointerAtIndex: i];
            break;
        }
    }
}

//- (void)removeAllNulls
//{
//    NSMutableSet *indexesToRemove = [NSMutableSet new];
//    for (NSUInteger i = 0; i < [_delegates count]; i++) {
//        if (![_delegates pointerAtIndex:i]) {
//            [indexesToRemove addObject:@(i)];
//        }
//    }
//
//    for (NSNumber *indexToRemove in indexesToRemove) {
//        [_delegates removePointerAtIndex:[indexToRemove unsignedIntegerValue]];
//    }
//}

#pragma mark - Send

-(double)realTotal:(double)amount fee:(double)fee {
    Amount bAmount = round(amount * Rules::Coin);
    Amount bTotal = bAmount + fee;
    double realAmount = double(int64_t(bTotal)) / Rules::Coin;
    return realAmount;
}

-(double)remaining:(double)amount fee:(double)fee {
    Amount bAmount = round(amount * Rules::Coin);
    Amount bTotal = bAmount + fee;
    Amount remaining = _walletStatus.available - bTotal;
    double realAmount = double(int64_t(remaining)) / Rules::Coin;
    return realAmount;
}

-(NSString*_Nullable)canSend:(double)amount fee:(double)fee to:(NSString*_Nullable)to {
    NSString *errorString = [self sendError:amount fee:fee to:to];
    return errorString;
}

-(NSString*_Nullable)canSendToMaxPrivacy:(NSString*_Nullable)to {
    for(BMPreparedTransaction *tr in _preparedTransactions) {
        if([tr.address isEqualToString:to]) {
            return [@"cant_send_to_max_privacy" localized];
        }
    }
    for(BMTransaction *tr in _transactions) {
        if([tr.token isEqualToString:to]) {
            return [@"cant_send_to_max_privacy" localized];
        }
    }
    
    return nil;
}

-(NSString*_Nullable)canSendOnlyUnlink:(double)amount fee:(double)fee to:(NSString*_Nullable)to {
    Amount bAmount = round(amount * Rules::Coin);
    Amount bTotal = bAmount + fee;
    Amount bMax = round(MAX_AMOUNT * Rules::Coin);
    
    if (amount==0) {
        return [@"amount_zero" localized];
    }
    else if(_walletStatus.shielded < bTotal)
    {
        double need = double(int64_t(bTotal - _walletStatus.shielded)) / Rules::Coin;
        
        NSString *beam = [CurrencyFormatter currencyFromNumber:[NSNumber numberWithDouble:need]];
        
        NSString *s = [@"insufficient_funds" localized];
        return [s stringByReplacingOccurrencesOfString:@"(value)" withString:beam];
    }
    else if (bTotal > bMax)
    {
        NSString *beam = [CurrencyFormatter currencyFromNumber:[NSNumber numberWithDouble:MAX_AMOUNT]];
        
        return [NSString stringWithFormat:@"Maximum amount %@ BEAMS",beam];
    }
    else if(![self isValidAddress:to])
    {
        return [@"incorrect_address" localized];
    }
    
    return nil;
}

-(NSString*_Nullable)canUnlink:(double)amount fee:(double)fee {
    NSString *errorString =  [self sendError:amount fee:fee checkMinAmount:YES];
    
    return errorString;
}

-(NSString*_Nullable)canReceive:(double)amount fee:(double)fee {
    
    Amount bAmount = round(amount * Rules::Coin);
    Amount bTotal = bAmount + fee;
    Amount bMax = round(MAX_AMOUNT * Rules::Coin);
    
    if (bTotal > bMax || (amount == MAX_AMOUNT && fee > 0))
    {
        NSString *beam = [CurrencyFormatter currencyFromNumber:[NSNumber numberWithDouble:MAX_AMOUNT]];
        
        return [NSString stringWithFormat:@"Maximum amount %@ BEAMS",beam];
    }
    
    return nil;
}

-(NSString*_Nullable)feeError:(double)fee {
    double need = double(int64_t(fee)) / Rules::Coin;
    
    NSString *beam = [CurrencyFormatter currencyFromNumber:[NSNumber numberWithDouble:need]];
    
    NSString *s = [@"insufficient_funds" localized];
    return [s stringByReplacingOccurrencesOfString:@"(value)" withString:beam];
}

-(void)calculateFee:(double)amount fee:(double)fee isShielded:(BOOL) isShielded result:(FeecalculatedBlock _Nonnull )block {
   
    self.isMaxPrivacyRequest = isShielded;

    self.feecalculatedBlock = block;
    
    Amount bAmount = round(amount * Rules::Coin);
    Amount bFee = fee;
    
    wallet->getAsync()->calcShieldedCoinSelectionInfo(bAmount + bFee, 0, beam::Asset::s_BeamID, isShielded);
}

-(void)calculateFee2:(double)amount fee:(double)fee isShielded:(BOOL) isShielded result:(FeecalculatedBlock _Nonnull )block {
    
    self.isMaxPrivacyRequest = isShielded;
    
    self.feecalculatedBlock = block;
    
    Amount bAmount = round(amount * Rules::Coin);
    Amount bFee = fee;
    
    wallet->getAsync()->calcShieldedCoinSelectionInfo(bAmount, bFee, beam::Asset::s_BeamID, isShielded);
}

-(NSString*)sendError:(double)amount fee:(double)fee checkMinAmount:(BOOL)check {
    
    Amount bAmount = round(amount * Rules::Coin);
    Amount bTotal = bAmount + fee;
    Amount bMax = round(MAX_AMOUNT * Rules::Coin);
    
    if (amount==0) {
        return [@"amount_zero" localized];
    }
    else if(_walletStatus.available < bTotal)
    {
        double need = double(int64_t(bTotal - _walletStatus.available)) / Rules::Coin;
        
        NSString *beam = [CurrencyFormatter currencyFromNumber:[NSNumber numberWithDouble:need]];
        
        NSString *s = [@"insufficient_funds" localized];
        return [s stringByReplacingOccurrencesOfString:@"(value)" withString:beam];
    }
    else if (bTotal > bMax)
    {
        NSString *beam = [CurrencyFormatter currencyFromNumber:[NSNumber numberWithDouble:MAX_AMOUNT]];
        
        return [NSString stringWithFormat:@"Maximum amount %@ BEAMS",beam];
    }
    else if (check) {
        auto min = [self getMinUnlinkFeeInGroth] + 1;
        if (bAmount < min) {
            double need = double(min) / Rules::Coin;
            NSString *beam = [CurrencyFormatter currencyFromNumber:[NSNumber numberWithDouble:need]];
            if([[beam substringToIndex:1] isEqualToString:@"."]) {
                beam = [NSString stringWithFormat:@"0%@",beam];
            }
            return [NSString stringWithFormat:@"%@ %@ BEAMS", [@"small_amount_unlink" localized], beam];
        }
    }
    
    return nil;
}

-(NSString*)sendError:(double)amount fee:(double)fee to:(NSString*_Nullable)to {
    NSString *error = [self sendError:amount fee:fee checkMinAmount:NO];
    
    if (error!=nil) {
        return error;
    }
    else if(![self isValidAddress:to])
    {
        return [@"incorrect_address" localized];
    }
    else{
        return nil;
    }
}

-(void)send:(double)amount fee:(double)fee to:(NSString*_Nonnull)to comment:(NSString*_Nonnull)comment {
    WalletID walletID(Zero);
    if (walletID.FromHex(to.string))
    {
        auto bAmount = round(amount * Rules::Coin);
        
        try{
            wallet->getAsync()->sendMoney(walletID, comment.string, bAmount, fee);
            wallet->getAsync()->getWalletStatus();
        }
        catch(NSException *ex) {
            NSLog(@"%@",ex);
        }
    }
}

-(void)send:(double)amount fee:(double)fee to:(NSString*_Nonnull)to comment:(NSString*_Nonnull)comment from:(NSString*_Nullable)from  {
        
    BOOL isShieldedTx = false;
    BOOL isMaxPrivacy = false;
    
    if([[AppModel sharedManager] isToken:from]) {
        BMTransactionParameters* params = [[AppModel sharedManager] getTransactionParameters:from];
        from = params.address;
    }
    
    auto txParameters = beam::wallet::ParseParameters(to.string);
    if (!txParameters)
    {
        return;
    }
    
    _txParameters = *txParameters;
    
    beam::wallet::PeerID _receiverIdentity = beam::Zero;

    if (auto peerIdentity = _txParameters.GetParameter<beam::PeerID>(TxParameterID::PeerWalletIdentity); peerIdentity) {
        _receiverIdentity = *peerIdentity;
    }
    
    if (auto txType = _txParameters.GetParameter<TxType>(TxParameterID::TransactionType); txType && *txType == TxType::PushTransaction)
    {
        isShieldedTx = true;
        
        ShieldedTxo::Voucher voucher;
        isMaxPrivacy = _txParameters.GetParameter(TxParameterID::Voucher, voucher) && _receiverIdentity != beam::Zero;
    }
    
    auto messageString = comment.string;
    
    uint64_t bAmount = round(amount * Rules::Coin);
    uint64_t bfee = fee;
    
    WalletID m_walletID(Zero);
    m_walletID.FromHex(from.string);
    
    auto params = CreateSimpleTransactionParameters();
    LoadReceiverParams(_txParameters, params);
   
    params.SetParameter(TxParameterID::Amount, bAmount)
        .SetParameter(TxParameterID::Fee, bfee)
        .SetParameter(beam::wallet::TxParameterID::MyID, m_walletID)
       // .SetParameter(beam::wallet::TxParameterID::AssetID, beam::Asset::s_BeamID)
        .SetParameter(TxParameterID::Message, beam::ByteBuffer(messageString.begin(), messageString.end()));
    
    if (isShieldedTx)
    {
        params.SetParameter(TxParameterID::TransactionType, TxType::PushTransaction);
    }
    if (isMaxPrivacy)
    {
        CopyParameter(TxParameterID::Voucher, _txParameters, params);
        params.SetParameter(TxParameterID::MaxPrivacyMinAnonimitySet, uint8_t(64));
    }
    if (isShieldedTx)
    {
        CopyParameter(TxParameterID::PeerOwnID, _txParameters, params);
    }
    
    if ([self isToken:to])
    {
        params.SetParameter(TxParameterID::OriginalToken, to.string);
    }
            
    NSString *toString = to;
    if([[AppModel sharedManager] isToken:toString]) {
        BMTransactionParameters* params = [[AppModel sharedManager] getTransactionParameters:toString];
        toString = params.address;
    }
    
    WalletID walletID(Zero);
    if (walletID.FromHex(toString.string))
    {
        try{
            __block auto address = walletDb->getAddress(walletID);
            
            if(address) {
                __block NSString *name = [NSString stringWithUTF8String:address->m_label.c_str()];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (address->isOwn()) {
                        [[AppModel sharedManager] setWalletComment:name toAddress:from];
                    }
                    else {
                        [[AppModel sharedManager] setContactComment:name toAddress:toString];
                    }
                });
            }
        }
        catch(NSException *ex) {
            NSLog(@"%@",ex);
        }
    }
    
    
    params.SetParameter(TxParameterID::SavePeerAddress, false);

    wallet->getAsync()->startTransaction(std::move(params));
}

void CopyParameter(beam::wallet::TxParameterID paramID, const beam::wallet::TxParameters& input, beam::wallet::TxParameters& dest)
{
    beam::wallet::ByteBuffer buf;
    if (input.GetParameter(paramID, buf))
    {
        dest.SetParameter(paramID, buf);
    }
}

-(void)prepareSend:(double)amount fee:(double)fee to:(NSString*_Nonnull)to comment:(NSString*_Nonnull)comment from:(NSString*_Nullable)from saveContact:(BOOL)saveContact maxPrivacy:(BOOL)maxPrivacy {
    
    BMPreparedTransaction *transaction = [[BMPreparedTransaction alloc] init];
    transaction.fee = fee;
    transaction.amount = amount;
    transaction.address = to;
    transaction.from = from;
    transaction.comment = comment;
    transaction.date = [[NSDate date] timeIntervalSince1970];
    transaction.ID = [NSString randomAlphanumericStringWithLength:10];
    transaction.saveContact = saveContact;
    transaction.maxPrivacy = maxPrivacy;
    
    [_preparedTransactions addObject:transaction];
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onAddedPrepareTransaction:)]) {
            [delegate onAddedPrepareTransaction:transaction];
        }
    }
}

-(NSString*_Nonnull)allAmount:(double)fee {
    Amount bAmount = _walletStatus.available - fee;
    
    double d = double(int64_t(bAmount)) / Rules::Coin;
    
    NSString *allValue =  [CurrencyFormatter currencyFromNumber:[NSNumber numberWithDouble:d]];
    allValue = [allValue stringByReplacingOccurrencesOfString:@"," withString:@""];
    
    if ([allValue hasPrefix:@"."])
    {
        allValue = [NSString stringWithFormat:@"0%@",allValue];
    }
    
    return allValue;
}

-(NSString*_Nonnull)allUnlinkAmount:(double)fee {
    Amount bAmount = _walletStatus.shielded - fee;
    
    double d = double(int64_t(bAmount)) / Rules::Coin;
    
    NSString *allValue =  [CurrencyFormatter currencyFromNumber:[NSNumber numberWithDouble:d]];
    allValue = [allValue stringByReplacingOccurrencesOfString:@"," withString:@""];
    
    if ([allValue hasPrefix:@"."])
    {
        allValue = [NSString stringWithFormat:@"0%@",allValue];
    }
    
    return allValue;
}

-(BMTransactionParameters*_Nonnull)getTransactionParameters:(NSString*_Nonnull)token {    
    auto params = beam::wallet::ParseParameters(token.string);
    auto amount = params->GetParameter<Amount>(TxParameterID::Amount);
    auto type = params->GetParameter<TxType>(TxParameterID::TransactionType);
    auto vouchers = params->GetParameter<ShieldedVoucherList>(TxParameterID::ShieldedVoucherList);
    auto isPermanentAddress = params->GetParameter<BOOL>(TxParameterID::IsPermanentPeerID);
    auto storedType = params->GetParameter<TxAddressType>(TxParameterID::AddressType);

    BMTransactionParameters *p = [BMTransactionParameters new];
    p.amount = 0.0;
    p.isMaxPrivacy = type == TxType::PushTransaction;
    
    auto gen = params->GetParameter<ShieldedTxo::PublicGen>(TxParameterID::PublicAddreessGen);
    if (gen)
    {
        p.isPublicOffline = true;
    }
    
    if(type == TxType::PushTransaction) {
        auto voucher = params->GetParameter<ShieldedTxo::Voucher>(TxParameterID::Voucher);
        p.isTrueMaxPrivacy = !!voucher;
    }

            
    if(amount) {
        p.amount = double(uint64_t(*amount)) / Rules::Coin;
    }
    
    if(vouchers) {
        p.isOffline = YES;
    }
    else {
        p.isOffline = NO;
    }
    
    if (auto isPermanentAddress = params->GetParameter<bool>(TxParameterID::IsPermanentPeerID); isPermanentAddress) {
        p.isPermanentAddress = *isPermanentAddress;
    }
    else {
        p.isPermanentAddress = NO;
    }
    
    if (auto walletIdentity = params->GetParameter<beam::PeerID>(TxParameterID::PeerWalletIdentity); walletIdentity)
    {
        auto s = std::to_string(*walletIdentity);
        p.identity = [NSString stringWithUTF8String:s.c_str()];
    }
    else {
        p.identity = @"";
    }
    
    if (auto peerIdentity = params->GetParameter<WalletID>(TxParameterID::PeerID); peerIdentity)
    {
        auto s = std::to_string(*peerIdentity);
        p.address = [NSString stringWithUTF8String:s.c_str()];
    }
    else {
        p.address = @"";
    }
    
    if (auto peerId = params->GetParameter<WalletID>(TxParameterID::PeerID); peerId)
    {
        ShieldedVoucherList trVouchers;
        if (params->GetParameter(TxParameterID::ShieldedVoucherList, trVouchers))
        {
            wallet->getAsync()->getAddress(*peerId);
            wallet->getAsync()->saveVouchers(trVouchers, *peerId);
        }
    }
    
    //    ProcessLibraryVersion(params, ((const std::string& version, const std::string& myVersion))
    //    });
    //    if (auto libVersion = params->GetParameter(TxParameterID::LibraryVersion); libVersion)
    //    {
    //        std::string libVersionStr;
    //        beam::wallet::fromByteBuffer(*libVersion, libVersionStr);
    //        std::string myLibVersionStr = BEAM_LIB_VERSION;
    //        std::regex libVersionRegex("\\d{1,}\\.\\d{1,}\\.\\d{4,}");
    //        if (std::regex_match(libVersionStr, libVersionRegex) &&
    //            std::lexicographical_compare(
    //                                         myLibVersionStr.begin(),
    //                                         myLibVersionStr.end(),
    //                                         libVersionStr.begin(),
    //                                         libVersionStr.end(),
    //                                         std::less<char>{}))
    //        {
    //            p.verionError = [NSString stringWithFormat:@"This address generated by newer Beam library version %@. Your version is: %@. Please, check for updates.", [NSString stringWithUTF8String:libVersionStr.c_str()], [NSString stringWithUTF8String:myLibVersionStr.c_str()]];
    //        }
    //    }
    
    return p;
}

#pragma mark - Logs

-(void)clearLogs {
    NSString *dataPath = [[Settings sharedManager] logPath];
    
    NSMutableArray *needRemove = [NSMutableArray new];
    
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dataPath error:nil];
    
    int days = [Settings sharedManager].logDays;
    if (days > 0) {
        NSTimeInterval period = 60 * 60 * (24*days);
        
        for (NSString *file in dirContents) {
            NSString *path = [dataPath stringByAppendingPathComponent:file];
            
            NSDictionary* fileAttribs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
            
            NSDate *result = [fileAttribs objectForKey:NSFileCreationDate];
            NSTimeInterval diff = [[NSDate date] timeIntervalSince1970] - [result timeIntervalSince1970];
            
            if (diff > period) {
                [needRemove addObject:path];
            }
        }
        
        for (NSString *file in needRemove) {
            [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
        }
    }
}

-(void)createLogger {
    NSString *dataPath = [[Settings sharedManager] logPath];
    
    [self clearLogs];
    
    
    static auto logger = beam::Logger::create(LOG_LEVEL_DEBUG,LOG_LEVEL_DEBUG,LOG_LEVEL_DEBUG,@"beam_".string, dataPath.string);
    
    auto path = logger->get_current_file_name();
    pathLog =  [NSString stringWithUTF8String:path.c_str()];
    
    auto s = std::string(BEAM_LIB_VERSION);
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    
    NSString *ios = [NSString stringWithFormat:@"OS VERSION: iOS %@",[[UIDevice currentDevice] systemVersion]];
    NSString *model = [NSString stringWithFormat:@"DEVICE TYPE: %@",[[UIDevice currentDevice] model]];
    NSString *modelID = [NSString stringWithFormat:@"DEVICE MODEL ID: %@",[self modelIdentifier]];
    NSString *appVersion = [NSString stringWithFormat:@"APP VERSION: %@ BUILD %@",version, build];
    NSString *langCode = [NSString stringWithFormat:@"LANGUAGE CODE: %@",[[NSLocale currentLocale] languageCode]];
    
    LOG_INFO() << "Application has started";
    LOG_INFO() << ios.string;
    LOG_INFO() << model.string;
    LOG_INFO() << modelID.string;
    LOG_INFO() << appVersion.string;
    LOG_INFO() << langCode.string;
    
}

- (NSString *)modelIdentifier {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

-(NSString*)getZipLogs {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = [paths objectAtIndex:0];
    
    BOOL isDir = NO;
    
    NSArray *subpaths;
    
    NSString *exportPath = docDirectory;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath isDirectory:&isDir] && isDir) {
        subpaths = [[NSFileManager defaultManager] subpathsAtPath:exportPath];
    }
    
    NSString *archivePath = [docDirectory stringByAppendingString:@"/logs.zip"];
    
    [SSZipArchive createZipFileAtPath:archivePath withContentsOfDirectory:[[Settings sharedManager] logPath]];
    
    return archivePath;
}

-(BOOL)checkIsOwnNode {
    if (wallet == nil) {
        return false;
    }
    return true;
//    auto own = wallet->isConnectionTrusted();
//    return own;
}


#pragma mark - Transactions

-(NSMutableArray<BMUTXO*>*_Nonnull)getUTXOSFromTransaction:(BMTransaction*_Nonnull)transaction {
    
    NSMutableArray *utxos = [NSMutableArray arrayWithArray:_utxos];
    [utxos addObjectsFromArray:_shildedUtxos];
    
    NSMutableArray *result = [NSMutableArray array];
    
    for(BMUTXO *utxo in utxos)
    {
        if (utxo.createTxId!=nil)
        {
            if([transaction.ID isEqualToString:utxo.createTxId])
            {
                [result addObject:utxo];
            }
        }
        if (utxo.spentTxId!=nil)
        {
            if([transaction.ID isEqualToString:utxo.spentTxId])
            {
                [result addObject:utxo];
            }
        }
        
    }
    
    return result;
}

-(BMPaymentInfo*_Nullable)validatePaymentProof:(NSString*_Nullable)code {
    auto buffer = beam::from_hex(code.string);
    try
    {
        auto paymentInfo = beam::wallet::storage::PaymentInfo::FromByteBuffer(buffer);
        BMPaymentInfo *info = [BMPaymentInfo new];
        info.realAmount = double(int64_t(paymentInfo.m_Amount)) / Rules::Coin;
        info.sender = [NSString stringWithUTF8String:to_string(paymentInfo.m_Sender).c_str()];
        info.receiver = [NSString stringWithUTF8String:to_string(paymentInfo.m_Receiver).c_str()];
        info.kernelId = [NSString stringWithUTF8String:to_string(paymentInfo.m_KernelID).c_str()];
        
        return info;
    }
    
    catch (...)
    {
    }
    
    try
    {
        auto shieldedPaymentInfo = beam::wallet::storage::ShieldedPaymentInfo::FromByteBuffer(buffer);
        BMPaymentInfo *info = [BMPaymentInfo new];
        info.realAmount = double(int64_t(shieldedPaymentInfo.m_Amount)) / Rules::Coin;
        info.sender = [NSString stringWithUTF8String:to_string(shieldedPaymentInfo.m_Sender).c_str()];
        info.receiver = [NSString stringWithUTF8String:to_string(shieldedPaymentInfo.m_Receiver).c_str()];
        info.kernelId = [NSString stringWithUTF8String:to_string(shieldedPaymentInfo.m_KernelID).c_str()];
        
        return info;
    }
    catch (...)
    {
    }
    
    return nil;
}

-(void)getPaymentProof:(BMTransaction*_Nonnull)transaction {
    wallet->getAsync()->exportPaymentProof([self txIDfromString:transaction.ID]);
}

-(BMPaymentInfo*_Nullable)getPaymentProofInfo:(NSString*_Nonnull)proof {
    if(proof.length == 0) {
        return nil;
    }
    auto buffer = beam::from_hex(proof.string);
    try
    {
        auto paymentInfo = beam::wallet::storage::PaymentInfo::FromByteBuffer(buffer);
        BMPaymentInfo *info = [BMPaymentInfo new];
        info.realAmount = double(int64_t(paymentInfo.m_Amount)) / Rules::Coin;
        info.sender = [NSString stringWithUTF8String:to_string(paymentInfo.m_Sender).c_str()];
        info.receiver = [NSString stringWithUTF8String:to_string(paymentInfo.m_Receiver).c_str()];
        info.kernelId = [NSString stringWithUTF8String:to_string(paymentInfo.m_KernelID).c_str()];

        return info;
    }
   
    catch (...)
    {
    }
   
    try
    {
        auto shieldedPaymentInfo = beam::wallet::storage::ShieldedPaymentInfo::FromByteBuffer(buffer);
        BMPaymentInfo *info = [BMPaymentInfo new];
        info.realAmount = double(int64_t(shieldedPaymentInfo.m_Amount)) / Rules::Coin;
        info.sender = [NSString stringWithUTF8String:to_string(shieldedPaymentInfo.m_Sender).c_str()];
        info.receiver = [NSString stringWithUTF8String:to_string(shieldedPaymentInfo.m_Receiver).c_str()];
        info.kernelId = [NSString stringWithUTF8String:to_string(shieldedPaymentInfo.m_KernelID).c_str()];

        return info;
    }
    catch (...)
    {
    }
    
    return nil;
}

-(void)prepareDeleteTransaction:(BMTransaction*_Nonnull)transaction {
    NSMutableArray <BMTransaction*> * _array = [NSMutableArray arrayWithArray:_transactions];
    
    [_preparedDeleteTransactions addObject:transaction];
    
    for (int i=0; i<_array.count; i++) {
        if ([_array[i].ID isEqualToString:transaction.ID])
        {
            [_array removeObjectAtIndex:i];
            break;
        }
    }
    
    [_transactions removeAllObjects];
    [_transactions addObjectsFromArray:_array];
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onAddedDeleteTransaction:)]) {
            [delegate onAddedDeleteTransaction:_preparedDeleteTransactions.lastObject];
        }
    }
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onReceivedTransactions:)]) {
            [delegate onReceivedTransactions:_transactions];
        }
    }
}

-(void)deleteTransaction:(NSString*_Nonnull)ID {
    for (int i=0;i<_preparedDeleteTransactions.count;i++)
    {
        if ([_preparedDeleteTransactions[i].ID isEqualToString:ID])
        {
            [_preparedDeleteTransactions removeObjectAtIndex:i];
            break;
        }
    }
    
    wallet->getAsync()->deleteTx([self txIDfromString:ID]);
    
    NSString *notificationId = [self getNotificationByObject:ID];
    if (notificationId!=nil) {
        [self deleteNotification:notificationId];
    }
}

-(void)cancelDeleteTransaction:(NSString*_Nonnull)ID {
    NSLog(@"cancelDeleteTransaction");
    
    BOOL found = NO;
    for (int i=0; i<_preparedDeleteTransactions.count; i++) {
        if ([_preparedDeleteTransactions[i].ID isEqualToString:ID]) {
            found = YES;
            [_preparedDeleteTransactions removeObjectAtIndex:i];
            break;
        }
    }
    
    if (found)
    {
        wallet->getAsync()->getWalletStatus();
        wallet->getAsync()->getTransactions();
    }
}

-(void)cancelTransaction:(BMTransaction*_Nonnull)transaction {
    wallet->getAsync()->cancelTx([self txIDfromString:transaction.ID]);
    wallet->getAsync()->getWalletStatus();
}

-(void)cancelPreparedTransaction:(NSString*_Nonnull)transaction {
    for (int i=0; i<_preparedTransactions.count; i++) {
        if ([_preparedTransactions[i].ID isEqualToString:transaction]) {
            [_preparedTransactions removeObjectAtIndex:i];
            break;
        }
    }
}

-(void)sendPreparedTransaction:(NSString*_Nonnull)transaction {
    for (int i=0; i<_preparedTransactions.count; i++) {
        if ([_preparedTransactions[i].ID isEqualToString:transaction]) {
            if (_preparedTransactions[i].from == nil) {
                [[AppModel sharedManager] send:_preparedTransactions[i].amount fee:_preparedTransactions[i].fee to:_preparedTransactions[i].address comment:_preparedTransactions[i].comment];
            }
            else{
                [[AppModel sharedManager] send:_preparedTransactions[i].amount fee:_preparedTransactions[i].fee to:_preparedTransactions[i].address comment:_preparedTransactions[i].comment from:_preparedTransactions[i].from];
            }
            
            if (!_preparedTransactions[i].saveContact) {
                [[AppModel sharedManager] deleteAddress:_preparedTransactions[i].address];
            }
            
            [_preparedTransactions removeObjectAtIndex:i];
            break;
        }
    }
}

-(void)cancelTransactionByID:(NSString*_Nonnull)transaction {
    wallet->getAsync()->cancelTx([self txIDfromString:transaction]);
}

-(void)resumeTransaction:(BMTransaction*_Nonnull)transaction {
    wallet->getAsync()->cancelTx([self txIDfromString:transaction.ID]);
}

-(TxID)txIDfromString:(NSString*)string {
    auto buffer = from_hex(string.string);
    TxID txID;
    
    std::copy_n(buffer.begin(), txID.size(), txID.begin());
    
    return txID;
}

-(void)exportTransactionsToCSV:(ExportCSVBlock _Nonnull)block {
    self.getCSVBlock = block;
    
    wallet->getAsync()->exportTxHistoryToCsv();
}


-(void)clearAllTransactions{
    for (BMTransaction *tr in _transactions) {
        [self deleteTransaction:tr.ID];
    }
}

-(BMTransaction*_Nullable)lastTransactionFromAddress:(NSString*_Nonnull)ID {
    NSMutableArray *transactions = [NSMutableArray arrayWithArray:_transactions];
    
    for (BMTransaction *tr in transactions) {
        if ([tr.senderAddress isEqualToString:ID] || [tr.receiverAddress isEqualToString:ID]) {
            return tr;
        }
    }
    
    return nil;
}

-(void)setTransactionStatusToFailed:(NSString*_Nonnull)ID  {
    NSMutableArray *transactions = [NSMutableArray arrayWithArray:_transactions];
    
    int i = 0;
    for (BMTransaction *tr in transactions) {
        if ([tr.ID isEqualToString:ID]) {
            _transactions[i].enumStatus = BMTransactionStatusFailed;
            _transactions[i].status = @"failed";
        }
        i ++;
    }
}

-(BMTransaction*_Nullable)transactionById:(NSString*_Nonnull)ID {
    NSMutableArray *transactions = [NSMutableArray arrayWithArray:_transactions];
    
    for (BMTransaction *tr in transactions) {
        if ([tr.ID isEqualToString:ID]) {
            return tr;
        }
    }
    
    return nil;
}

-(NSString*_Nullable)getFirstTransactionIdForAddress:(NSString*_Nonnull)address {
    NSMutableArray *transactions = [NSMutableArray arrayWithArray:_transactions];
    
    NSString *_id = nil;
    
    for (BMTransaction *tr in transactions) {
        if ([tr.receiverAddress isEqualToString:address] && tr.isIncome) {
            _id =  tr.ID;
        }
    }
    
    return _id;
}

-(BOOL)hasActiveTransactions {
    for (BMTransaction *tr in self.transactions.reverseObjectEnumerator)
    {
        if(tr.enumStatus == BMTransactionStatusPending || tr.enumStatus == BMTransactionStatusInProgress
           || tr.enumStatus == BMTransactionStatusRegistering) {
            return YES;
        }
    }
    
    return NO;
}

-(void)calculateChange:(double)amount fee:(double)fee {
    Amount bAmount = round(amount * Rules::Coin);
    Amount bFee = fee;
    wallet->getAsync()->calcChange(bAmount, bFee, beam::Asset::s_BeamID);
}

#pragma mark - UTXO

-(void)setUtxos:(NSMutableArray<BMUTXO *> *)utxos {
    _utxos = utxos;
}

-(void)getUTXO {
    if (wallet != nil)  {
        wallet->getAsync()->getUtxosStatus();
    }
}

-(NSMutableArray<BMTransaction*>*_Nonnull)getTransactionsFromUTXO:(BMUTXO*_Nonnull)utox {
    NSMutableArray *result = [NSMutableArray array];
    NSMutableArray *transactions = [NSMutableArray arrayWithArray:self.transactions];

    for (BMTransaction *tr in transactions)
    {
        if (utox.createTxId!=nil)
        {
            if([tr.ID isEqualToString:utox.createTxId])
            {
                [result addObject:tr];
            }
        }
        if (utox.spentTxId!=nil)
        {
            if([tr.ID isEqualToString:utox.spentTxId])
            {
                [result addObject:tr];
            }
        }
    }
    return result;
}

#pragma mark - Contacts

-(BMContact*_Nullable)getContactFromId:(NSString*_Nonnull)idValue {
    for (BMContact *contact in _contacts) {
        if([contact.address.walletId isEqualToString:idValue])
        {
            return contact;
        }
    }
    
    
    return nil;
}

-(void)clearAllContacts{
    for (BMContact *contact in _contacts) {
        [self deleteAddress:contact.address.walletId];
    }
}

#pragma mark - Categories

-(void)setContacts:(NSMutableArray<BMContact *> *)contacts {
    _contacts = contacts;
}

-(BMCategory*_Nullable)findCategoryById:(NSString*_Nullable)ID {
    if (ID.isEmpty) {
        return nil;
    }
    
    for (BMCategory *cat in _categories.reverseObjectEnumerator) {
        if (cat.ID == ID.intValue) {
            return cat;
        }
    }
    
    return nil;
}

-(NSUInteger)findCategoryIndex:(int)ID {
    for (int i=0; i<_categories.count; i++) {
        if (_categories[i].ID == ID) {
            return i;
        }
    }
    
    return 0;
}

-(BOOL)isCategoryAdded:(int)ID {
    for (int i=0; i<_categories.count; i++) {
        if (_categories[i].ID == ID) {
            return YES;
        }
    }
    
    return NO;
}

-(NSMutableArray<BMCategory*>*_Nonnull)allCategories{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:categoriesKey]) {
        NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:categoriesKey];
        
        NSMutableArray *array = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
        
        return array;
    }
    
    return @[].mutableCopy;
}

-(void)deleteCategory:(BMCategory*_Nonnull)category {
    [_categories removeObjectAtIndex:[self findCategoryIndex:category.ID]];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_categories];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:categoriesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSMutableArray *addresses = [NSMutableArray arrayWithArray:[[AppModel sharedManager] getAddressesFromCategory:category]];
    for (BMAddress *address in addresses) {
        for (int i=0; i<address.categories.count; i++) {
            if ([address.categories[i] intValue] == category.ID) {
                [address.categories removeObjectAtIndex:i];
                [[AppModel sharedManager] editCategoryAddress:address];
                break;
            }
        }
    }
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onCategoriesChange)]) {
            [delegate onCategoriesChange];
        }
    }
}

-(void)updateCategory:(BMCategory*_Nonnull)category {
    if ([self isCategoryAdded:category.ID]) {
        NSUInteger index = [self findCategoryIndex:category.ID];
        [_categories replaceObjectAtIndex:index withObject:category];
    }
    else{
        [_categories addObject:category];
    }
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_categories];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:categoriesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onCategoriesChange)]) {
            [delegate onCategoriesChange];
        }
    }
}

-(void)editCategory:(BMCategory*_Nonnull)category {
    NSUInteger index = [self findCategoryIndex:category.ID];
    
    [_categories replaceObjectAtIndex:index withObject:category];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_categories];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:categoriesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onCategoriesChange)]) {
            [delegate onCategoriesChange];
        }
    }
}

-(void)addCategory:(BMCategory*_Nonnull)category {
    [_categories addObject:category];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_categories];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:categoriesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onCategoriesChange)]) {
            [delegate onCategoriesChange];
        }
    }
}

-(BOOL)isNameAlreadyExist:(NSString*_Nonnull)name id:(int)ID{
    for(BMCategory *category in _categories.reverseObjectEnumerator) {
        if (ID == 0) {
            if ([category.name isEqualToString:name]) {
                return YES;
            }
        }
        else{
            if ([category.name isEqualToString:name] && category.ID != ID) {
                return YES;
            }
        }
    }
    
    return NO;
}

-(NSMutableArray<BMContact*>*_Nonnull)getOnlyContactsFromCategory:(BMCategory*_Nonnull)category {
    NSMutableArray *addresses = [NSMutableArray array];
    
    NSMutableArray *contacts = [NSMutableArray arrayWithArray:_contacts];
    
    for (BMContact *contact in contacts) {
        for (NSString *c in contact.address.categories) {
            if (c.intValue == category.ID) {
                [addresses addObject:contact];
            }
        }
    }
    
    return addresses;
}

-(NSMutableArray<BMAddress*>*_Nonnull)getOnlyAddressesFromCategory:(BMCategory*_Nonnull)category {
    NSMutableArray *addresses = [NSMutableArray array];
    
    NSMutableArray *walletAddresses = [NSMutableArray arrayWithArray:_walletAddresses];
    
    for (BMAddress *address in walletAddresses) {
        for (NSString *c in address.categories) {
            if (c.intValue == category.ID) {
                [addresses addObject:address];
            }
        }
    }
    
    
    return addresses;
}

-(NSMutableArray<BMAddress*>*_Nonnull)getAddressesFromCategory:(BMCategory*_Nonnull)category {
    NSMutableArray *addresses = [NSMutableArray array];
    
    NSMutableArray *walletAddresses = [NSMutableArray arrayWithArray:_walletAddresses];
    
    for (BMAddress *address in walletAddresses) {
        for (NSString *c in address.categories) {
            if (c.intValue == category.ID) {
                [addresses addObject:address];
            }
        }
    }
    
    NSMutableArray *contacts = [NSMutableArray arrayWithArray:_contacts];
    
    for (BMContact *contact in contacts) {
        for (NSString *c in contact.address.categories) {
            if (c.intValue == category.ID) {
                [addresses addObject:contact.address];
            }
        }
    }
    
    return addresses;
}

-(void)clearAllCategories {
    [_categories removeAllObjects];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:categoriesKey];
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onCategoriesChange)]) {
            [delegate onCategoriesChange];
        }
    }
}

-(NSArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector
{
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
    NSInteger sectionCount = [[collation sectionTitles] count]; //section count is take from sectionTitles and not sectionIndexTitles
    NSMutableArray *unsortedSections = [NSMutableArray arrayWithCapacity:sectionCount];
    
    //create an array to hold the data for each section
    for(int i = 0; i < sectionCount; i++)
    {
        [unsortedSections addObject:[NSMutableArray array]];
    }
    
    //put each object into a section
    for (id object in array)
    {
        NSInteger index = [collation sectionForObject:object collationStringSelector:selector];
        [[unsortedSections objectAtIndex:index] addObject:object];
    }
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:sectionCount];
    
    //sort each section
    for (NSMutableArray *section in unsortedSections)
    {
        [sections addObject:[collation sortedArrayFromArray:section collationStringSelector:selector]];
    }
    return sections;
}

-(NSMutableArray<BMCategory*>*_Nonnull)sortedCategories {
    NSArray *sections = [self partitionObjects:_categories collationStringSelector:@selector(name)];
    
    NSMutableArray *sorted = [NSMutableArray array];
    
    for (NSArray *arr in sections) {
        if(arr.count > 0) {
            NSSortDescriptor *sortDescriptor;
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
                                                         ascending:YES];
            NSArray *sortedArray = [arr sortedArrayUsingDescriptors:@[sortDescriptor]];
            
            [sorted addObjectsFromArray:sortedArray];
        }
    }
    
    return sorted;
}

-(void)fixCategories {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"fix"] intValue]==1) {
        return;
    }
    
    NSMutableArray *walletAddresses = [NSMutableArray arrayWithArray:_walletAddresses];
    
    for (BMAddress *address in walletAddresses) {
        NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
        
        for (int i=0; i<address.categories.count; i++) {
            
            BMCategory *cat = [[AppModel sharedManager] findCategoryById:address.categories[i]];
            if (cat==nil) {
                [set addIndex:i];
            }
        }
        
        if (set.count>0) {
            [address.categories removeObjectsAtIndexes:set];
            [[AppModel sharedManager] editAddress:address];
        }
    }
    
    NSMutableArray *contacts = [NSMutableArray arrayWithArray:_contacts];
    
    for (BMContact *contact in contacts) {
        NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
        
        for (int i=0; i<contact.address.categories.count; i++) {
            
            BMCategory *cat = [[AppModel sharedManager] findCategoryById:contact.address.categories[i]];
            if (cat==nil) {
                [set addIndex:i];
            }
        }
        
        if (set.count>0) {
            [contact.address.categories removeObjectsAtIndexes:set];
            [[AppModel sharedManager] editAddress:contact.address];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"fix"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Fork

-(BOOL)isFork {
    BOOL isFork = walletDb->getCurrentHeight() >= Rules::get().pForks[1].m_Height;
    return isFork;
}

-(int)getDefaultFeeInGroth {
    return [self isFork] ? kFeeInGroth_Fork1 : kDefaultFeeInGroth;
}

-(int)getMinFeeInGroth {
    return [self isFork] ? kFeeInGroth_Fork1 : 0;
}

-(int)getMinUnlinkFeeInGroth {
    return kFeeInGroth_Unlink;
}

-(int)getMinMaxPrivacyFeeInGroth {
    return kFeeInGroth_MaxPrivacy;
}

bool IsValidTimeStamp(Timestamp currentBlockTime_s)
{
    Timestamp currentTime_s = getTimestamp();
    const Timestamp tolerance_s = 60 * 10; // 10 minutes tolerance.
    currentBlockTime_s += tolerance_s;
    
    if (currentTime_s > currentBlockTime_s)
    {
        LOG_INFO() << "It seems that node is not up to date";
        return false;
    }
    return true;
}

#pragma mark - Timer

-(void)handleTimer {
    [[AppModel sharedManager] setIsNodeChanging:NO];
    
    [[AppModel sharedManager].connectionTimer invalidate];
    [AppModel sharedManager].connectionTimer = nil;
    
    [[AppModel sharedManager] setIsConnecting:NO];
    [[AppModel sharedManager] setIsConnected: wallet->pre_connected_status];
    [[AppModel sharedManager] getNetworkStatus];
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onNetwotkStatusChange:)]) {
            [delegate onNetwotkStatusChange:[AppModel sharedManager].isConnected];
        }
    }
}

-(void)startConnectionTimer:(int)seconds {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([AppModel sharedManager].connectionTimer!=nil) {
            [[AppModel sharedManager].connectionTimer invalidate];
            [AppModel sharedManager].connectionTimer = nil;
        }
        
        self.connectionTimer =  [NSTimer scheduledTimerWithTimeInterval:seconds
                                                                 target: self
                                                               selector: @selector(handleTimer)
                                                               userInfo: nil
                                                                repeats: NO];
        
    });
}

-(void)completeWalletVerification {
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onWalletCompleteVerefication)]) {
            [delegate onWalletCompleteVerefication];
        }
    }
}

//MARK: - Export, Import

-(BOOL)importData:(NSString*_Nonnull)jsonString {
    NSError *error = nil;
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
        return NO;
    }
    
    auto _data = [jsonString string];
    bool result = storage::ImportDataFromJson(*walletDb, &_data[0], _data.size());
    
    if (result) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers
                                                                                                                          error:nil]];
        if ([dictionary objectForKey:@"Categories"]) {
            NSMutableArray *categories = [NSMutableArray arrayWithArray:[dictionary objectForKey:@"Categories"]];
            
            for (NSDictionary *dict in categories) {
                [self updateCategory:[BMCategory fromDict:dict]];
            }
        }
    }
    return result;
}

-(NSString*_Nonnull)exportData:(NSArray*_Nonnull)items{
    auto exported = storage::ExportDataToJson(*walletDb);
    NSString *result = [NSString stringWithUTF8String:exported.c_str()];
    
    NSData *objectData = [result dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[NSJSONSerialization JSONObjectWithData:objectData options:NSJSONReadingMutableContainers
                                                                                                                      error:nil]];
    
    if (![items containsObject:@"transaction"]) {
        [dictionary removeObjectForKey:@"TransactionParameters"];
    }
    
    if (![items containsObject:@"category"]) {
        [dictionary removeObjectForKey:@"Categories"];
    }
    else {
        NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:categoriesKey];
        
        NSMutableArray *array = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
        
        NSMutableArray *categories = [NSMutableArray array];
        
        for (BMCategory *cat in array) {
            [categories addObject:cat.dict];
        }
        
        [dictionary setObject:categories forKey:@"Categories"];
    }
    
    if (![items containsObject:@"address"]) {
        [dictionary removeObjectForKey:@"OwnAddresses"];
    }
    
    if (![items containsObject:@"contact"]) {
        [dictionary removeObjectForKey:@"Contacts"];
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

-(NSString*_Nonnull)exchangeValue:(double)amount to:(BMCurrencyType)to {
    for (BMCurrency *currency in [_currencies objectEnumerator].allObjects) {
        if(currency.type == to && currency.value > 0) {
            currencyFormatter.maximumFractionDigits = currency.maximumFractionDigits;
            currencyFormatter.positiveSuffix = [NSString stringWithFormat:@" %@",currency.code];
            currencyFormatter.negativeSuffix = [NSString stringWithFormat:@" %@",currency.code];
            
            double value = double(int64_t(currency.value)) / Rules::Coin;
            double rate = value * amount;
            return [currencyFormatter stringFromNumber:[NSNumber numberWithDouble:rate]];
        }
    }

    return @"";
}

-(NSString*_Nonnull)exchangeValue:(double)amount {
    if(Settings.sharedManager.currency == BMCurrencyOff || [self isCurrenciesAvailable] == NO) {
        return @"";
    }
    if(amount == 0.0) {
        return [NSString stringWithFormat:@"-%@",Settings.sharedManager.currencyName];
    }
    for (BMCurrency *currency in [_currencies objectEnumerator].allObjects) {
        if(currency.type == Settings.sharedManager.currency && currency.value > 0) {
            currencyFormatter.maximumFractionDigits = currency.maximumFractionDigits;
            currencyFormatter.positiveSuffix = [NSString stringWithFormat:@" %@",currency.code];
            currencyFormatter.negativeSuffix = [NSString stringWithFormat:@" %@",currency.code];
            
            double value = double(int64_t(currency.value)) / Rules::Coin;
            double rate = value * amount;
            return [currencyFormatter stringFromNumber:[NSNumber numberWithDouble:rate]];
        }
    }
    
    return [NSString stringWithFormat:@"-%@",Settings.sharedManager.currencyName];
}

-(NSString*_Nonnull)exchangeValueFrom2:(BMCurrencyType)from to:(BMCurrencyType)to amount:(double)amount {
    if(Settings.sharedManager.currency == BMCurrencyOff || [self isCurrenciesAvailable] == NO) {
        return @"";
    }
    if(amount == 0) {
        return @"";
    }
    
    if(from == BEAM) {
        for (BMCurrency *currency in _currencies) {
            if(currency.type == Settings.sharedManager.currency && currency.value > 0) {
                currencyFormatter.maximumFractionDigits = currency.maximumFractionDigits;
                currencyFormatter.positiveSuffix = [NSString stringWithFormat:@" %@",currency.code];
                
                double value = double(int64_t(currency.value)) / Rules::Coin;
                double rate = value * (amount / Rules::Coin);
                if(rate < 0.01 && currency.type == BMCurrencyUSD) {
                    return @"< 1 cent";
                }
                NSString *result = [currencyFormatter stringFromNumber:[NSNumber numberWithDouble:rate]];
                if([result isEqualToString:@"0 BTC"]) {
                    rate = rate * 100000000;
                    currencyFormatter.positiveSuffix = [NSString stringWithFormat:@" %@",@"satoshis"];
                    result = [currencyFormatter stringFromNumber:[NSNumber numberWithDouble:rate]];
                }
                return result;
            }
        }
        
        return [NSString stringWithFormat:@"-%@",Settings.sharedManager.currencyName];
    }
    else  {
        for (BMCurrency *currency in _currencies) {
            if(currency.type == from && currency.value > 0) {
      
                NSNumberFormatter *formatter = [NSNumberFormatter new];
                formatter.currencyCode = @"";
                formatter.currencySymbol = @"";
                formatter.minimumFractionDigits = 0;
                formatter.maximumFractionDigits = 2;
                formatter.numberStyle = NSNumberFormatterCurrencyStyle;
                formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
                
                double value = double(int64_t(currency.value)) / Rules::Coin;
                double rate = (amount) / value;
                NSString *result = [NSString stringWithFormat:@"%@ BEAM",[formatter stringFromNumber:[NSNumber numberWithDouble:rate]]];
                return result;
            }
        }
        
        return [NSString stringWithFormat:@"-%@",Settings.sharedManager.currencyName];
    }
}

-(NSString*_Nonnull)exchangeValueFee:(double)amount {
    if(Settings.sharedManager.currency == BMCurrencyOff || [self isCurrenciesAvailable] == NO) {
        return @"";
    }
    if(amount == 0) {
        return @"";
    }
    for (BMCurrency *currency in _currencies) {
        if(currency.type == Settings.sharedManager.currency && currency.value > 0) {
            currencyFormatter.maximumFractionDigits = currency.maximumFractionDigits;
            currencyFormatter.positiveSuffix = [NSString stringWithFormat:@" %@",currency.code];
            
            double value = double(int64_t(currency.value)) / Rules::Coin;
            double rate = value * (amount / Rules::Coin);
            if(rate < 0.01 && currency.type == BMCurrencyUSD) {
                return @"< 1 cent";
            }
            NSString *result = [currencyFormatter stringFromNumber:[NSNumber numberWithDouble:rate]];
            if([result isEqualToString:@"0 BTC"]) {
                rate = rate * 100000000;
                currencyFormatter.positiveSuffix = [NSString stringWithFormat:@" %@",@"satoshis"];
                result = [currencyFormatter stringFromNumber:[NSNumber numberWithDouble:rate]];
            }
            return result;
        }
    }
    
    return [NSString stringWithFormat:@"-%@",Settings.sharedManager.currencyName];
}

#pragma mark - Notifications

-(int)getUnreadNotificationsCount {
    int count = 0;
    
    for (BMNotification *notification in AppModel.sharedManager.notifications) {
        if(!notification.isRead) {
            if (notification.type == TRANSACTION) {
                BMTransaction *tr = [[AppModel sharedManager] transactionById:notification.pId];
                if (tr != nil) {
                    count += 1;
                }
            }
        }
    }
    
    return count;
}

-(int)getUnsendedNotificationsCount {
    int count = 0;
    
    for (BMNotification *notification in AppModel.sharedManager.notifications) {
        if(!notification.isSended && !notification.isRead) {
            count += 1;
        }
    }
    
    return count;
}

-(BMNotification*_Nullable)getUnsendedNotification {
    for (BMNotification *notification in AppModel.sharedManager.notifications) {
        if(!notification.isSended && !notification.isRead) {
            return notification;
        }
    }
    return nil;
}

-(BMNotification*_Nullable)getLastVersionNotification {
    for (BMNotification *notification in AppModel.sharedManager.notifications) {
        if(notification.type == VERSION && !notification.isRead) {
            return notification;
        }
    }
    return nil;
}

-(BOOL)allUnsendedIsAddresses {
    for (BMNotification *notification in AppModel.sharedManager.notifications) {
        if(notification.type != ADDRESS && !notification.isSended && !notification.isRead) {
            return NO;
        }
    }
    return YES;
}

-(void)readNotification:(NSString*_Nonnull) notifId {
    auto buffer = from_hex(notifId.string);
    Blob rawData(buffer.data(), static_cast<uint32_t>(buffer.size()));
    ECC::uintBig nid(rawData);
    wallet->getAsync()->markNotificationAsRead(nid);
}

-(void)readNotificationByObject:(NSString*_Nonnull) objectId {
    NSMutableArray *notifications = [NSMutableArray arrayWithArray:_notifications];
    for (BMNotification *notification in notifications) {
        if([notification.pId isEqualToString:objectId]) {
            [self readNotification:notification.nId];
            break;
        }
    }
}

-(NSString*_Nullable)getNotificationByObject:(NSString*_Nonnull) objectId {
    NSMutableArray *notifications = [NSMutableArray arrayWithArray:_notifications];
    for (BMNotification *notification in notifications) {
        if([notification.pId isEqualToString:objectId]) {
            return notification.nId;
        }
    }
    
    return nil;
}

-(void)deleteNotification:(NSString*_Nonnull) notifId {
    auto buffer = from_hex(notifId.string);
    Blob rawData(buffer.data(), static_cast<uint32_t>(buffer.size()));
    ECC::uintBig nid(rawData);
    wallet->getAsync()->deleteNotification(nid);
}

-(void)deleteAllNotifications {
    NSMutableArray *notifications = [NSMutableArray arrayWithArray:_notifications];
    for (BMNotification *notification in notifications) {
        [self deleteNotification:notification.nId];
    }
}

-(void)sendNotifications {
    for (BMNotification *notification in AppModel.sharedManager.notifications) {
        if(!notification.isSended) {
            notification.isSended = YES;
            [_presendedNotifications setObject:notification.nId forKey:notification.nId];
        }
    }
}

-(void)clearNotifications {
    [_notifications removeAllObjects];
    [_presendedNotifications removeAllObjects];
}

-(void)readAllNotifications {
    NSMutableArray *notifications = [NSMutableArray arrayWithArray:_notifications];
    for (BMNotification *notification in notifications) {
        if(![notification isRead]) {
            [self readNotification: notification.nId];
        }
    }
}

-(BOOL)isCurrenciesAvailable {
    return (_currencies.count > 0);
}

-(void)setMaxPrivacyLockTime:(int)hours {
    wallet->getAsync()->setMaxPrivacyLockTimeLimitHours(hours);
}

-(NSString*_Nonnull)getMaturityHoursLeft:(BMUTXO*_Nonnull)utxo {
    uint64_t _id = utxo.txoID;
    auto coin = wallet->shieldedCoins[_id];
    auto time = wallet->getMaturityHoursLeft(coin);
    return [self formatHours: time];
}

-(UInt64)getMaturityHours:(BMUTXO*_Nonnull)utxo {
    uint64_t _id = utxo.txoID;
    auto coin = wallet->shieldedCoins[_id];
    auto time = wallet->getMaturityHoursLeft(coin);
    return time;
}

-(NSString*_Nonnull)formatHours:(int) hours {
    double f = (double)hours/24.0;
    
    auto dd = floor(f);
    auto hh = hours;
    if (dd) {
        hh = hours - dd * 24;
    }
    
    
    NSString *res = @"";
    
    if (hh == 1) {
        res = [NSString stringWithFormat:@"%d hour", hh];
    } else if (hh == 0){
        res = [NSString stringWithFormat:@""];
    } else {
        res = [NSString stringWithFormat:@"%d hours", hh];
    }
    
    if (dd) {
        if (dd == 1) {
            return [NSString stringWithFormat:@"%d day %@", (int)dd , res];;
        } else {
            return [NSString stringWithFormat:@"%d days %@", (int)dd , res];;
        }
        
    }
    
    return res;
}

@end

