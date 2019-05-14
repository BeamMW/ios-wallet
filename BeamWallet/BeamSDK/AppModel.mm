//
// AppModel.m
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
#import <UIKit/UIKit.h>
#import "Reachability.h"

#import "AppModel.h"
#import "MnemonicModel.h"
#import "WalletModel.h"
#import "StringStd.h"
#import "NodeModel.h"
#import "DiskStatusManager.h"
#import "CurrencyFormatter.h"

#import <SSZipArchive/SSZipArchive.h>

#include "wallet/wallet.h"
#include "wallet/wallet_db.h"
#include "wallet/wallet_network.h"
#include "wallet/wallet_model_async.h"
#include "wallet/wallet_client.h"

#include "utility/bridge.h"
#include "utility/string_helpers.h"
//#include "utility/options.h"

#include "mnemonic/mnemonic.h"

#include "common.h"

#include <sys/sysctl.h>
#import <sys/utsname.h>

using namespace beam;
using namespace ECC;
using namespace std;
using namespace beam::io;

static int proofSize = 330;
static NSString *categoriesKey = @"categoriesKey";

@implementation AppModel  {
    BOOL isStarted;
    BOOL isRunning;

    NSTimer *utxoTimer;
    
    Reachability *internetReachableFoo;

    IWalletDB::Ptr walletDb;
    WalletModel::Ptr wallet;
    Reactor::Ptr walletReactor;
    NodeModel nodeModel;

    ECC::NoLeak<ECC::uintBig> passwordHash;
    
    NSString *pathLog;
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
    
     walletReactor = Reactor::create();
    
    _delegates = [[NSHashTable alloc] init];
    
    _transactions = [[NSMutableArray alloc] init];
    
    _contacts = [[NSMutableArray alloc] init];
    
    _categories = [[NSMutableArray alloc] initWithArray:[self allCategories]];
    
    [self checkInternetConnection];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActiveNotification)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self cancelForgotPassword];

    return self;
}

#pragma mark - Inetrnet

-(void)checkInternetConnection{
    internetReachableFoo = [Reachability reachabilityWithHostName:@"www.google.com"];
    
    internetReachableFoo.reachableBlock = ^(Reachability*reach)
    {
        if (![[AppModel sharedManager] isInternetAvailable]) {
            [[AppModel sharedManager] refreshAllInfo];
        }
        
        [[AppModel sharedManager] setIsInternetAvailable:YES];
        [[AppModel sharedManager] start];
    };
    
    internetReachableFoo.unreachableBlock = ^(Reachability*reach)
    {
        [[AppModel sharedManager] setIsInternetAvailable:NO];
        [[AppModel sharedManager] setIsConnected:NO];
        
        for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
        {
            if ([delegate respondsToSelector:@selector(onNetwotkStatusChange:)]) {
                [delegate onNetwotkStatusChange:NO];
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

-(void)setIsLocalNodeStarted:(BOOL)isLocalNodeStarted {
    _isLocalNodeStarted = isLocalNodeStarted;
    
    if (_isLocalNodeStarted) {
        if ([[Settings sharedManager] isLocalNode]) {
            wallet->start();
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
               
              ///  self->nodeModel.stopNode();

              ///  string nodeAddrStr = [Settings sharedManager].nodeAddress.string;
               
              ///  self->wallet->getAsync()->setNodeAddress(nodeAddrStr);

                for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
                {
                    if ([delegate respondsToSelector:@selector(onLocalNodeStarted)]) {
                        [delegate onLocalNodeStarted];
                    }
                }
                
           ///     [[NSFileManager defaultManager] removeItemAtPath:[Settings sharedManager].localNodeStorage error:nil];
                
                if([AppModel sharedManager].isForgotPasswordFlow) {
                    [[AppModel sharedManager] stopForgotPassword];
                }
            });
        }
    }
}

-(void)setIsRestoreFlow:(BOOL)isRestoreFlow {
    _isRestoreFlow = isRestoreFlow;
    
    if (_isRestoreFlow) {
        if (!nodeModel.isStarted())
        {
            nodeModel.start();
        }
    }
    
    [Settings sharedManager].isLocalNode = _isRestoreFlow;
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
    Rules::get().UpdateChecksum();
    
    if (walletReactor == nil) {
        walletReactor = Reactor::create();
    }
    
    string dbFilePath = Settings.sharedManager.walletStoragePath.string;
    
    if (!walletDb) {
        walletDb = WalletDB::open(dbFilePath, pass.string, walletReactor);
        
        if (!walletDb){
            return NO;
        }
    }
    
    [self onWalledOpened:SecString(pass.string)];
    
    return YES;
}

-(BOOL)canOpenWallet:(NSString*)pass {
    Rules::get().UpdateChecksum();
    
    if (walletReactor == nil) {
        walletReactor = Reactor::create();
    }
    
    string dbFilePath = [Settings sharedManager].walletStoragePath.string;
    
    if (walletDb != nil) {
        return YES;
    }
    
    walletDb = WalletDB::open(dbFilePath, pass.string, walletReactor);
    
    if (!walletDb) {
        return NO;
    }
    
//    if ([[NSFileManager defaultManager] fileExistsAtPath:[Settings sharedManager].localNodeStorage]) {
//        // self.isRestoreFlow = YES;
//        
//        if (!nodeModel.isStarted())
//        {
//            nodeModel.start();
//        }
//        
//        [Settings sharedManager].isLocalNode = YES;
//    }
    
    return YES;
}

-(BOOL)isValidPassword:(NSString*_Nonnull)pass {
    auto hash = SecString(pass.string).hash();
    
    return hash.V == passwordHash.V;
}

-(BOOL)createWallet:(NSString*)phrase pass:(NSString*)pass {
    if (self.isInternetAvailable == NO) {
        return NO;
    }
        
    Rules::get().UpdateChecksum();

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
     walletDb = WalletDB::init(dbFilePath, SecString(pass.string), seed.hash(), walletReactor);
    
    if (!walletDb) {
        return NO;
    }
    
    // generate default address
    auto address = wallet::createAddress(*walletDb);
    address.m_label = "default";
    walletDb->saveAddress(address);
    
    [self onWalledOpened:SecString(pass.string)];
    
    return YES;
}

-(void)resetWallet:(BOOL)removeDatabase {
    if (self.isRestoreFlow) {
        self.isRestoreFlow = NO;
        self->nodeModel.stopNode();
    }
    
    isStarted = NO;
    isRunning = NO;

    walletReactor.reset();
    walletDb.reset();
    wallet.reset();
    
    walletReactor = nil;
    wallet = nil;
    walletDb = nil;

    if(removeDatabase) {
        [[NSFileManager defaultManager] removeItemAtPath:[Settings sharedManager].walletStoragePath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:[Settings sharedManager].localNodeStorage error:nil];
    }
}


-(BOOL)isWalletInitialized{
    if (walletDb != nil && wallet != nil) {
        return YES;
    }
    
    return NO;
}

-(void)onWalledOpened:(const SecString&) pass {
    passwordHash = pass.hash();
    
    [self start];
}

-(void)start {
    if (isStarted == NO && walletDb != nil) {
        Rules::get().UpdateChecksum();
        
        string nodeAddrStr = [Settings sharedManager].nodeAddress.string;
        
        if ([[Settings sharedManager] isLocalNode]) {
            
            nodeModel.setKdf(walletDb->get_MasterKdf());
            
            nodeModel.startNode();
            
            io::Address nodeAddr = io::Address::LOCALHOST;
            nodeAddr.port([[Settings sharedManager] nodePort]);
            nodeAddrStr = nodeAddr.str();
        }
        
        wallet = make_shared<WalletModel>(walletDb, nodeAddrStr, walletReactor);
        wallet->getAsync()->setNodeAddress(nodeAddrStr);
        
        if (![[Settings sharedManager] isLocalNode] && self.isInternetAvailable) {
            isRunning = YES;
            wallet->start();
        }
        
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
            wallet->start();
        }
    }
}

-(void)startForgotPassword{
    _isForgotPasswordFlow = YES;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[Settings sharedManager].walletStoragePath]) {
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/wallet_old"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath] == YES) {
            [[NSFileManager defaultManager] removeItemAtPath:dataPath error:nil];
        }
        
        [[NSFileManager defaultManager] copyItemAtPath:[Settings sharedManager].walletStoragePath toPath:dataPath error:nil];
        
        [[NSFileManager defaultManager] removeItemAtPath:[Settings sharedManager].walletStoragePath error:nil];
    }
}

-(void)stopForgotPassword {
    _isForgotPasswordFlow = NO;

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/wallet_old"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        
        [[NSFileManager defaultManager] removeItemAtPath:dataPath error:nil];
    }
}

-(void)cancelForgotPassword {
    _isForgotPasswordFlow = NO;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/wallet_old"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        
        [[NSFileManager defaultManager] copyItemAtPath:dataPath toPath:[Settings sharedManager].walletStoragePath error:nil];
        
        [[NSFileManager defaultManager] removeItemAtPath:dataPath error:nil];
    }
}

-(void)changePassword:(NSString*_Nonnull)pass {
    auto password = SecString(pass.string);
    
    passwordHash = password.hash();

    wallet->getAsync()->changeWalletPassword(password);
}

-(void)changeNodeAddress {
    if (![Settings sharedManager].isLocalNode) {
        [self setIsConnecting:YES];

        string nodeAddrStr = [Settings sharedManager].nodeAddress.string;
        wallet->getAsync()->setNodeAddress(nodeAddrStr);
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
    Address nodeAddr;
    BOOL isValid =  nodeAddr.resolve(string.string.c_str());
    return isValid;
}

#pragma mark - Updates

-(void)getWalletStatus {
    wallet->getAsync()->getWalletStatus();
}

-(void)getNetworkStatus {
    wallet->getAsync()->getNetworkStatus();
}

-(void)refreshAllInfo{
    [internetReachableFoo stopNotifier];
    [internetReachableFoo startNotifier];
    
    if (wallet != nil) {
        [self setIsConnecting:true];
        
        [self getNetworkStatus];
        
        if (self.isConnected)
        {
            [self getWalletStatus];
        }
    }
}

-(void)didBecomeActiveNotification{
    if ([Settings sharedManager].target == Testnet)
    {
        [internetReachableFoo stopNotifier];
        [internetReachableFoo startNotifier];
    }
    else{
        [self refreshAllInfo];
    }
}

#pragma mark - Addresses

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
    else if (address.length == 0)
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
            std::vector<WalletAddress> addresses = walletDb->getAddresses(true);
            
            for (int i=0; i<addresses.size(); i++)
            {
                NSString *wAddress = [NSString stringWithUTF8String:to_string(addresses[i].m_walletID).c_str()];
                
                if ([wAddress isEqualToString:address])
                {
                    wallet->getAsync()->saveAddressChanges(walletID, "telegram bot", true, true, false);
                    
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
        std::vector<WalletAddress> addresses = walletDb->getAddresses(true);
        
        for (int i=0; i<addresses.size(); i++)
        {
            NSString *wAddress = [NSString stringWithUTF8String:to_string(addresses[i].m_walletID).c_str()];
            
            if ([wAddress isEqualToString:address])
            {
                wallet->getAsync()->saveAddressChanges(walletID, addresses[i].m_label, (hours == 0 ? true : false), true, false);
                
                break;
            }
        }
    }
}

-(void)setWalletComment:(NSString*)comment toAddress:(NSString*_Nonnull)address {
    WalletID walletID(Zero);
    if (walletID.FromHex(address.string))
    {
        std::vector<WalletAddress> addresses = walletDb->getAddresses(true);
        
        for (int i=0; i<addresses.size(); i++)
        {
            NSString *wAddress = [NSString stringWithUTF8String:to_string(addresses[i].m_walletID).c_str()];
            
            if ([wAddress isEqualToString:address])
            {
                wallet->getAsync()->saveAddressChanges(walletID, comment.string, (addresses[i].m_duration == 0 ? true : false), true, false);

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
       // walletDb->deleteAddress(walletID);
    }
}


-(void)generateNewWalletAddress {
    wallet->getAsync()->generateNewAddress();
}
    
-(void)generateNewWalletAddressWithBlock:(NewAddressGeneratedBlock _Nonnull )block{
    self.generatedNewAddressBlock = block;
    
    wallet->getAsync()->generateNewAddress();
}

-(NSMutableArray<BMAddress*>*_Nonnull)getWalletAddresses {
    std::vector<WalletAddress> addrs = walletDb->getAddresses(true);

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
    
    return addresses;
}

-(NSMutableArray<BMTransaction*>*_Nonnull)getTransactionsFromAddress:(BMAddress*_Nonnull)address {
    
    NSMutableArray *result = [NSMutableArray array];
    for (BMTransaction *tr in self.transactions)
    {
        if ([tr.senderAddress isEqualToString:address.walletId]
            || [tr.receiverAddress isEqualToString:address.walletId]) {
            [result addObject:tr];
        }
    }
    
    return result;
}

-(void)editAddress:(BMAddress*_Nonnull)address {
    WalletID walletID(Zero);
    if (walletID.FromHex(address.walletId.string))
    {
        //TODO: ENABLE for categories
        
//        std::vector<WalletAddress> addresses = walletDb->getAddresses(true);
//
//        for (int i=0; i<addresses.size(); i++)
//        {
//            NSString *wAddress = [NSString stringWithUTF8String:to_string(addresses[i].m_walletID).c_str()];
//
//            NSString *wCategory = [NSString stringWithUTF8String:addresses[i].m_category.c_str()];
//
//            if ([wAddress isEqualToString:address.walletId] && ![wCategory isEqualToString:address.category])
//            {
//                addresses[i].m_category = address.category.string;
//
//                wallet->getAsync()->saveAddress(addresses[i], true);
//
//                break;
//            }
//        }
        
        if(address.isNowExpired) {
            wallet->getAsync()->saveAddressChanges(walletID, address.label.string, false, false, true);
        }
        else if(address.isNowActive) {
            if (address.isNowActiveDuration == 0){
                wallet->getAsync()->saveAddressChanges(walletID, address.label.string, true, true, false);
            }
            else{
                wallet->getAsync()->saveAddressChanges(walletID, address.label.string, false, true, false);
            }
        }
        else{
            if (address.isExpired) {
                wallet->getAsync()->saveAddressChanges(walletID, address.label.string, false, false, true);
            }
            else  {
                address.isChangedDate = YES;
                
                wallet->getAsync()->saveAddressChanges(walletID, address.label.string, (address.duration == 0 ? true : false), address.isChangedDate ? true : false, false);
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

#pragma mark - Delegates

-(void)addDelegate:(id<WalletModelDelegate>) delegate{
    if(![_delegates containsObject:delegate])
    {
        [_delegates addObject: delegate];
    }
}

-(void)removeDelegate:(id<WalletModelDelegate>) delegate {
    [_delegates removeObject: delegate];
}

#pragma mark - Send

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

-(NSString*)sendError:(double)amount fee:(double)fee to:(NSString*_Nullable)to {
    
    Amount bAmount = round(amount * Rules::Coin);
    Amount bTotal = bAmount + fee;
    Amount bMax = round(MAX_AMOUNT * Rules::Coin);

    if(![self isValidAddress:to])
    {
        return @"Incorrect address";
    }
    else if (amount==0) {
        return @"Amount can’t be 0";;
    }
    else if(_walletStatus.available < bTotal)
    {
        double need = double(int64_t(bTotal - _walletStatus.available)) / Rules::Coin;

        NSString *beam = [CurrencyFormatter currencyFromNumber:[NSNumber numberWithDouble:need]];

        return [NSString stringWithFormat:@"Insufficient funds: you would need %@ beams to complete the transaction",beam];
    }
    else if (bTotal > bMax)
    {
        NSString *beam = [CurrencyFormatter currencyFromNumber:[NSNumber numberWithDouble:MAX_AMOUNT]];
        
        return [NSString stringWithFormat:@"Maximum amount %@ BEAMS",beam];
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
        }
        catch(NSException *ex) {
            NSLog(@"%@",ex);
        }
    }
}

-(NSString*_Nonnull)allAmount:(double)fee {
    Amount bAmount = _walletStatus.available - fee;
    
    double d = double(int64_t(bAmount)) / Rules::Coin;
    
    NSString *allValue =  [CurrencyFormatter currencyFromNumber:[NSNumber numberWithDouble:d]];
    allValue = [allValue stringByReplacingOccurrencesOfString:@"," withString:@""];
    
    return allValue;
}

#pragma mark - Logs

-(void)createLogger {
    NSString *dataPath = [[Settings sharedManager] logPath];
    
    NSMutableArray *needRemove = [NSMutableArray new];
    
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dataPath error:nil];
    
    NSTimeInterval period = 60 * 60 * (24*3); //3 day
    
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
    
    
    static auto logger = beam::Logger::create(LOG_LEVEL_DEBUG,LOG_LEVEL_DEBUG,LOG_LEVEL_DEBUG,@"beam_".string, dataPath.string);
    
    auto path = logger->get_current_file_name();
    pathLog =  [NSString stringWithUTF8String:path.c_str()];
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];

    NSString *ios = [NSString stringWithFormat:@"OS VERSION: iOS %@",[[UIDevice currentDevice] systemVersion]];
    NSString *model = [NSString stringWithFormat:@"DEVICE TYPE: %@",[[UIDevice currentDevice] model]];
    NSString *modelID = [NSString stringWithFormat:@"DEVICE MODEL ID: %@",[self modelIdentifier]];
    NSString *appVersion = [NSString stringWithFormat:@"APP VERSION: %@ BUILD %@",version, build];

    LOG_INFO() << "Application has started";
    LOG_INFO() << ios.string;
    LOG_INFO() << model.string;
    LOG_INFO() << modelID.string;
    LOG_INFO() << appVersion.string;
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
    NSMutableArray *result = [NSMutableArray array];
    
    for(BMUTXO *utxo in _utxos)
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
    
    if (result.count > 1)
    {
        BMUTXO *total = [[BMUTXO alloc] init];
        total.statusString = @"total";
        
        for(BMUTXO *utxo in result)
        {
            total.realAmount = total.realAmount + utxo.realAmount;
            
        }
        
        [result insertObject:total atIndex:0];
    }
    
    return result;
}

-(BMTransaction*_Nullable)validatePaymentProof:(NSString*_Nullable)code {
    if (code == nil || code.length < proofSize) {
        return nil;
    }
    
    try{
        auto buffer = from_hex(code.string);
        beam::wallet::PaymentInfo m_paymentInfo = wallet::PaymentInfo::FromByteBuffer(buffer);
        
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

-(void)deleteTransaction:(BMTransaction*_Nonnull)transaction {
    wallet->getAsync()->deleteTx([self txIDfromString:transaction.ID]);
}

-(void)cancelTransaction:(BMTransaction*_Nonnull)transaction {
    wallet->getAsync()->cancelTx([self txIDfromString:transaction.ID]);
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

-(void)exportTransactionsToCSV:(void(^_Nonnull)(NSURL*_Nonnull))callback {
    NSTimeInterval date = [[NSDate date] timeIntervalSince1970];
    
    NSString *fileName = [NSString stringWithFormat:@"transactions_%d.csv",(int)date];
    NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    
    NSString *csvText = @"Type,Date | Time,\"Amount, BEAM\",Status,Sending address,Receiving address,\"Transaction fee, BEAM\",Transaction ID,Kernel ID\n";

    for (BMTransaction *tr in _transactions) {
        NSString *newLine = [tr csvLine];
        csvText = [csvText stringByAppendingString:newLine];
    }
    
    [csvText writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    callback(url);
}

-(void)clearAllTransactions{
    for (BMTransaction *tr in _transactions) {
        [self deleteTransaction:tr];
    }
}

#pragma mark - UTXO

-(void)onSyncWithLocalNodeCompleted {
    if ([Settings sharedManager].isLocalNode) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

            self->nodeModel.stopNode();
            
            string nodeAddrStr = [Settings sharedManager].nodeAddress.string;
            
            self->wallet->getAsync()->setNodeAddress(nodeAddrStr);
            
            [[NSFileManager defaultManager] removeItemAtPath:[Settings sharedManager].localNodeStorage error:nil];
        });
           
        self.isLocalNodeStarted = NO;
        self.isRestoreFlow = NO;
    }
}

-(void)setUtxos:(NSMutableArray<BMUTXO *> *)utxos {
    _utxos = utxos;
}

-(void)getUTXO {
    wallet->getAsync()->getUtxosStatus();
}

-(NSMutableArray<BMTransaction*>*_Nonnull)getTransactionsFromUTXO:(BMUTXO*_Nonnull)utox {
    NSMutableArray *result = [NSMutableArray array];
    for (BMTransaction *tr in self.transactions)
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

-(NSMutableArray<BMUTXO*>*_Nonnull)getUTXOWithPadding:(BOOL)active page:(int)page perPage:(int)perPage {
    
    NSArray *filteredArray = [self.utxos filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        if (active) {
            if ([(BMUTXO*)object isActive]) {
                return YES;
            }
            else{
                return NO;
            }
        }
        
        return YES;
    }]];
    
    NSMutableArray *result = [NSMutableArray array];

    if(filteredArray.count >= (perPage*page)) {
        result = [NSMutableArray arrayWithArray:[filteredArray subarrayWithRange:NSMakeRange(0, perPage*page)]];
    }
    else{
        [result addObjectsFromArray:filteredArray];
    }
    
    [result sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        BMUTXO *utxo_1 = (BMUTXO*)obj1;
        BMUTXO *utxo_2 = (BMUTXO*)obj2;
        
        if (utxo_1.ID > utxo_2.ID) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        else{
            return (NSComparisonResult)NSOrderedDescending;
        }
    }];
    
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

-(BMCategory*_Nullable)findCategoryById:(NSString*)ID {
    if (ID.isEmpty) {
        return nil;
    }
    
    for (int i=0; i<_categories.count; i++) {
        if (_categories[i].ID == ID.intValue) {
            return _categories[i];
        }
    }
    
    return nil;
}

-(BMCategory*_Nullable)findCategoryByAddress:(NSString*_Nonnull)ID {
    if (ID.isEmpty) {
        return nil;
    }
    
    for (BMAddress *address in _walletAddresses) {
        if ([address.walletId isEqualToString:ID]) {
            return [self findCategoryById:address.category];
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
    for(BMCategory *category in _categories) {
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

-(NSMutableArray<BMAddress*>*_Nonnull)getAddressFromCategory:(BMCategory*_Nonnull)category {
    NSMutableArray *addresses = [NSMutableArray array];
    
    for (BMAddress *address in _walletAddresses) {
        if (address.category.intValue == category.ID) {
            [addresses addObject:address];
        }
    }
    
    return addresses;
}

@end
