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

#import <SSZipArchive/SSZipArchive.h>

#include "wallet/core/wallet.h"

#include "wallet/core/wallet_db.h"
#include "wallet/core/wallet_network.h"
#include "wallet/client/wallet_model_async.h"
#include "wallet/client/wallet_client.h"
#include "wallet/core/default_peers.h"

#include "core/block_rw.h"

#include "utility/bridge.h"
#include "utility/string_helpers.h"

#include "mnemonic/mnemonic.h"

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

const int kDefaultFeeInGroth = 10;
const int kFeeInGroth_Fork1 = 100;

const std::map<Notification::Type,bool> activeNotifications {
    { Notification::Type::SoftwareUpdateAvailable, true },
    { Notification::Type::BeamNews, true },
    { Notification::Type::TransactionStatusChanged,true },
    { Notification::Type::TransactionCompleted, true },
    { Notification::Type::TransactionFailed, true },
    { Notification::Type::AddressStatusChanged, true }
};

const bool isSecondCurrencyEnabled = true;

@implementation AppModel  {
    BOOL isStarted;
    BOOL isRunning;

    NSString *localPassword;
    NSTimer *utxoTimer;
    
    Reachability *internetReachableFoo;

    IWalletDB::Ptr walletDb;
    WalletModel::Ptr wallet;
    Reactor::Ptr walletReactor;

    ECC::NoLeak<ECC::uintBig> passwordHash;
    
    NSString *pathLog;
    
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

-(id)init{
    self = [super init];
    
    [self createLogger];
    
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
    
    _contacts = [[NSMutableArray alloc] init];
    _notifications = [[NSMutableArray alloc] init];
    _presendedNotifications = [[NSMutableDictionary alloc] init];
    
    _preparedTransactions = [[NSMutableArray alloc] init];
    _preparedDeleteAddresses = [[NSMutableArray alloc] init];
    _preparedDeleteTransactions = [[NSMutableArray alloc] init];
    _currencies = [[NSMutableArray alloc] initWithArray:[self allCurrencies]];
    
    _isRestoreFlow = [[NSUserDefaults standardUserDefaults] boolForKey:restoreFlowKey];
        
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
    LOG_INFO() << "Rules signature";
}

+(NSString*_Nonnull)chooseRandomNode {
    auto peers = getDefaultPeers();
    
    NSMutableArray *array = [NSMutableArray array];
    
    for (const auto& item : peers)
    {
        [array addObject:[NSString stringWithUTF8String:item.c_str()]];
    }
    
    srand([[NSDate date]  timeIntervalSince1970]);
    
    int inx =rand()%[array count];

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
        
        wallet = make_shared<WalletModel>(walletDb, nodeAddrStr, walletReactor);
        wallet->getAsync()->setNodeAddress(nodeAddrStr);
        
        wallet->start(activeNotifications, isSecondCurrencyEnabled);

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
            wallet->start(activeNotifications, isSecondCurrencyEnabled);
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

#pragma mark - Addresses

-(void)refreshAddresses{
    if (wallet != nil)  {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.walletAddresses = [self getWalletAddresses];
        });
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
    if (address==nil)
    {
        return NO;
    }
    else if (address.length < 60)
    {
        return NO;
    }
        
    WalletID walletID(Zero);
    return walletID.FromHex(address.string);
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
            || [tr.receiverAddress isEqualToString:address.walletId]) {
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
            || [tr.receiverAddress isEqualToString:address.walletId]) {
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
            || [tr.receiverAddress isEqualToString:address.walletId]) {
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
            WalletAddress _address;
            _address.m_label = address.label.string;
            _address.m_category = [address.categories componentsJoinedByString:@","].string;
            _address.m_walletID = walletID;
            _address.m_createTime = NSDate.date.timeIntervalSince1970;
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
            WalletAddress _address;
            _address.m_label = address.label.string;
            _address.m_category = [address.categories componentsJoinedByString:@","].string;
            _address.m_walletID = walletID;
            _address.m_createTime = NSDate.date.timeIntervalSince1970;
            walletDb->saveAddress(_address);
        }
    }
    else{
        WalletID walletID(Zero);
        if (walletID.FromHex(address.walletId.string))
        {
            std::vector<WalletAddress> addresses = wallet->ownAddresses;
            
            for (int i=0; i<addresses.size(); i++)
            {
                NSString *wAddress = [NSString stringWithUTF8String:to_string(addresses[i].m_walletID).c_str()];
                
                NSString *wCategory = [NSString stringWithUTF8String:addresses[i].m_category.c_str()];
                
                if ([wAddress isEqualToString:address.walletId] && ![wCategory isEqualToString:[address.categories componentsJoinedByString:@","]])
                {
                    addresses[i].m_category = [address.categories componentsJoinedByString:@","].string;
                    wallet->getAsync()->saveAddress(addresses[i], true);
                    
                    break;
                }
            }
            
            if(address.isNowExpired) {
                wallet->getAsync()->updateAddress(walletID, address.label.string, WalletAddress::ExpirationStatus::Expired);
            }
            else if(address.isNowActive) {
                if (address.isNowActiveDuration == 0){
                    wallet->getAsync()->updateAddress(walletID, address.label.string, WalletAddress::ExpirationStatus::Never);
                }
                else{
                    wallet->getAsync()->updateAddress(walletID, address.label.string, WalletAddress::ExpirationStatus::OneDay);
                }
            }
            else{
                if (address.isExpired) {
                    wallet->getAsync()->updateAddress(walletID, address.label.string, WalletAddress::ExpirationStatus::Expired);
                }
                else  {
                    wallet->getAsync()->updateAddress(walletID, address.label.string, address.duration == 0 ? WalletAddress::ExpirationStatus::Never : WalletAddress::ExpirationStatus::AsIs);
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
    if (amount!=nil) {
        NSString *trimmed = [amount stringByReplacingOccurrencesOfString:@"," withString:@"."];
        if (trimmed.doubleValue > 0) {
            qrString = [qrString stringByAppendingString:[NSString stringWithFormat:@"?amount=%@",trimmed]];
        }
    }
    
    return  qrString;
}

-(void)addContact:(NSString*_Nonnull)addressId name:(NSString*_Nonnull)name categories:(NSArray*_Nonnull)categories {
    
    WalletID walletID(Zero);
    if (walletID.FromHex(addressId.string))
    {
        WalletAddress address;
        address.m_label = name.string;
        address.m_category = [categories componentsJoinedByString:@","].string;
        address.m_walletID = walletID;
        address.m_createTime = NSDate.date.timeIntervalSince1970;
        walletDb->saveAddress(address);
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

-(NSString*_Nullable)canSend:(double)amount fee:(double)fee to:(NSString*_Nullable)to {
   
    NSString *errorString =  [self sendError:amount fee:fee to:to];
    
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

-(NSString*)sendError:(double)amount fee:(double)fee to:(NSString*_Nullable)to {
    
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

-(void)send:(double)amount fee:(double)fee to:(NSString*_Nonnull)to comment:(NSString*_Nonnull)comment from:(NSString*_Nullable)from {
    
    WalletID walletID(Zero);
    if (walletID.FromHex(to.string))
    {
        WalletID fromID(Zero);
        fromID.FromHex(from.string);
        
        auto bAmount = round(amount * Rules::Coin);
        
        try{
           __block BMAddress *address = [[AppModel sharedManager] findAddressByID:to];
            
            wallet->getAsync()->sendMoney(fromID, walletID, comment.string, bAmount, fee);
            wallet->getAsync()->getWalletStatus();

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([[AppModel sharedManager] isMyAddress:to]) {
                    [[AppModel sharedManager] setWalletComment:address.label toAddress:address.walletId];
                }
                else if (address != nil){
                    [[AppModel sharedManager] setContactComment:address.label toAddress:address.walletId];
                }
            });
        }
        catch(NSException *ex) {
            NSLog(@"%@",ex);
        }
    }
}

-(void)prepareSend:(double)amount fee:(double)fee to:(NSString*_Nonnull)to comment:(NSString*_Nonnull)comment from:(NSString*_Nullable)from saveContact:(BOOL)saveContact {

    BMPreparedTransaction *transaction = [[BMPreparedTransaction alloc] init];
    transaction.fee = fee;
    transaction.amount = amount;
    transaction.address = to;
    transaction.from = from;
    transaction.comment = comment;
    transaction.date = [[NSDate date] timeIntervalSince1970];
    transaction.ID = [NSString randomAlphanumericStringWithLength:10];
    transaction.saveContact = saveContact;
    
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

#pragma mark - Transactions

-(NSMutableArray<BMUTXO*>*_Nonnull)getUTXOSFromTransaction:(BMTransaction*_Nonnull)transaction {
    
    NSMutableArray *utxos = [NSMutableArray arrayWithArray:_utxos];
    
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

-(BMTransaction*_Nullable)validatePaymentProof:(NSString*_Nullable)code {
    if (code == nil || code.length < proofSize) {
        return nil;
    }
    
    try{
        auto buffer = from_hex(code.string);
        beam::wallet::storage::PaymentInfo m_paymentInfo = beam::wallet::storage::PaymentInfo::FromByteBuffer(buffer);
        
        if (m_paymentInfo.IsValid()) {
            auto kernelId = to_hex(m_paymentInfo.m_KernelID.m_pData, m_paymentInfo.m_KernelID.nBytes);
            
            BMTransaction *transaction = [[BMTransaction alloc] init];
            transaction.realAmount = double(int64_t(m_paymentInfo.m_Amount)) / Rules::Coin;
            transaction.senderAddress = [NSString stringWithUTF8String:to_string(m_paymentInfo.m_Sender).c_str()];
            transaction.receiverAddress = [NSString stringWithUTF8String:to_string(m_paymentInfo.m_Receiver).c_str()];
            transaction.kernelId = [NSString stringWithUTF8String:kernelId.c_str()];
            
            return transaction;
        }
    }
    catch (const std::exception& e) {
        return nil;
    }
    catch (...) {
        return nil;
    }
    
    return nil;
}

-(void)getPaymentProof:(BMTransaction*_Nonnull)transaction {
    wallet->getAsync()->exportPaymentProof([self txIDfromString:transaction.ID]);
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

-(NSURL*_Nonnull)exportTransactionsToCSV:(NSArray<BMTransaction*>*_Nonnull)transactions {
    
    NSTimeInterval date = [[NSDate date] timeIntervalSince1970];
    
    NSString *fileName = [NSString stringWithFormat:@"transactions_%d.csv",(int)date];
    NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    
    NSString *csvText = @"Type,Date | Time,\"Amount, BEAM\",Status,Sending address,Receiving address,\"Transaction fee, BEAM\",Transaction ID,Kernel ID\n";

    for (BMTransaction *tr in transactions) {
        NSString *newLine = [tr csvLine];
        csvText = [csvText stringByAppendingString:newLine];
    }
    
    [csvText writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    return url;
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
    for (BMTransaction *tr in self.transactions.reverseObjectEnumerator)
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

-(NSString*_Nonnull)exchangeValue:(double)amount {
    for (BMCurrency *currency in _currencies) {
        if(currency.type == Settings.sharedManager.currency) {
            currencyFormatter.maximumFractionDigits = currency.maximumFractionDigits;
            currencyFormatter.positiveSuffix = [NSString stringWithFormat:@" %@",currency.code];

            double value = double(int64_t(currency.value)) / Rules::Coin;
            double rate = value * amount;
            return [currencyFormatter stringFromNumber:[NSNumber numberWithDouble:rate]];
        }
    }

    return @"";
}

-(NSString*_Nonnull)exchangeValueFee:(double)amount {
    if(amount == 0) {
        return @"";
    }
    for (BMCurrency *currency in _currencies) {
        if(currency.type == Settings.sharedManager.currency) {
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
    
    return @"";
}

#pragma mark - Notifications

-(int)getUnreadNotificationsCount {
    int count = 0;
    
    for (BMNotification *notification in AppModel.sharedManager.notifications) {
        if(!notification.isRead) {
            count += 1;
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


@end

