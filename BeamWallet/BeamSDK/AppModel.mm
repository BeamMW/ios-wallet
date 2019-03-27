//
//  AppModel.m
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
#import <UIKit/UIKit.h>
#import "Reachability.h"

#import "AppModel.h"
#import "Settings.h"
#import "MnemonicModel.h"
#import "WalletModel.h"
#import "StringStd.h"

#import <SSZipArchive/SSZipArchive.h>

#include "wallet/wallet.h"
#include "wallet/wallet_db.h"
#include "wallet/wallet_network.h"
#include "wallet/wallet_model_async.h"
#include "wallet/wallet_client.h"

#include "utility/bridge.h"
#include "utility/string_helpers.h"
#include "utility/options.h"

#include "mnemonic/mnemonic.h"

#include "common.h"

#include <sys/sysctl.h>
#import <sys/utsname.h>

using namespace beam;
using namespace ECC;
using namespace std;
using namespace beam::io;


@implementation AppModel  {
    Reachability *internetReachableFoo;

    IWalletDB::Ptr walletDb;
    WalletModel::Ptr wallet;
    Reactor::Ptr walletReactor;

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
    
    walletReactor = Reactor::create();

    [self createLogger];
    
    _delegates = [[NSHashTable alloc] init];
    
    _transactions = [[NSMutableArray alloc] init];
    
    [self checkEthernetConnection];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshAllInfo)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    return self;
}

-(void)checkEthernetConnection{
    internetReachableFoo = [Reachability reachabilityWithHostName:@"www.google.com"];
    
    internetReachableFoo.reachableBlock = ^(Reachability*reach)
    {
        if (![[AppModel sharedManager] isInternetAvailable]) {
            [[AppModel sharedManager] refreshAllInfo];
        }
        
        [[AppModel sharedManager] setIsInternetAvailable:YES];
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


-(BOOL)isWalletAlreadyAdded {
    return [[NSFileManager defaultManager] fileExistsAtPath:Settings.walletStoragePath];
}

-(BOOL)openWallet:(NSString*)pass {
    
    Rules::get().UpdateChecksum();
    
    string dbFilePath = Settings.walletStoragePath.string;
    
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

    string dbFilePath = Settings.walletStoragePath.string;

    walletDb = WalletDB::open(dbFilePath, pass.string, walletReactor);
    if (!walletDb) {
        return NO;
    }
    
    return YES;
}

-(BOOL)createWallet:(NSString*)phrase pass:(NSString*)pass {
    Rules::get().UpdateChecksum();

    string dbFilePath = Settings.walletStoragePath.string;

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

-(void)resetWallet{
    walletDb.reset();
    wallet.reset();
    
    [[NSFileManager defaultManager] removeItemAtPath:Settings.walletStoragePath error:nil];
}

-(void)onWalledOpened:(const SecString&) pass {
    passwordHash = pass.hash();
    
    [self start];
}

-(void)start {
    string nodeAddr = Settings.nodeAddress.string;
    
    wallet = make_shared<WalletModel>(walletDb, nodeAddr, walletReactor);
    
    wallet->getAsync()->setNodeAddress(nodeAddr);
    
    wallet->start();
}


//-(void)refreshWallet {
//   // wallet->getAsync()->refresh();
//}

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
    }
}


#pragma mark - Address

-(BOOL)isExpiredAddress:(NSString*_Nullable)address {
    if (address!=nil) {
        if(address.length)
        {
            WalletID walletID(Zero);
            if (walletID.FromHex(address.string))
            {
                auto receiverAddr = walletDb->getAddress(walletID);
                
                if(receiverAddr) {
                    if (receiverAddr->m_OwnID && receiverAddr->isExpired())
                    {
                        return YES;
                    }
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
        walletDb->deleteAddress(walletID);
    }
}

-(void)generateNewWalletAddress {    
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
            wallet->getAsync()->saveAddressChanges(walletID, address.label.string, (address.duration == 0 ? true : false), false, false);
        }
    }
}

#pragma mark - Delegates

-(void)addDelegate:(id<WalletModelDelegate>) delegate{
    [_delegates addObject: delegate];
}

-(void)removeDelegate:(id<WalletModelDelegate>) delegate {
    [_delegates removeObject: delegate];
}

#pragma mark - Send

-(NSString*_Nullable)canSend:(double)amount fee:(double)fee to:(NSString*_Nullable)to {
   
    NSString *errorString =  [self sendError:amount fee:fee to:to];
    
    return errorString;
}

-(NSString*)sendError:(double)amount fee:(double)fee to:(NSString*_Nullable)to {
    Amount bAmount = round(amount * Rules::Coin);
    Amount bTotal = bAmount + fee;
    

    if([self isExpiredAddress:to]){
        return @"Can't send to the expired address";
    }
    else if(![self isValidAddress:to])
    {
        return @"Incorrect address";
    }
    else if (amount==0) {
        return @"Amount can’t be 0";;
    }
    else if(_walletStatus.available < bTotal)
    {
        double need = double(int64_t(bTotal - _walletStatus.available)) / Rules::Coin;
        
        NSNumberFormatter *currencyFormatter = [NSNumberFormatter new];
        currencyFormatter.usesGroupingSeparator = true;
        currencyFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        currencyFormatter.currencyCode = @"";
        currencyFormatter.currencyCode = @"";
        currencyFormatter.minimumIntegerDigits = 0;
        currencyFormatter.minimumFractionDigits = 0;
        currencyFormatter.minimumSignificantDigits = 0;
        currencyFormatter.maximumIntegerDigits = 20;
        currencyFormatter.maximumFractionDigits = 20;
        currencyFormatter.maximumSignificantDigits = 20;
        
        NSString *beam = [currencyFormatter stringFromNumber:[NSNumber numberWithDouble:need]];
        
        return [NSString stringWithFormat:@"Insufficient funds: you would need %@ beams to complete the transaction",beam];
    }
    else{
        return nil;
    }
}

-(void)send:(double)amount fee:(double)fee to:(NSString*_Nonnull)to comment:(NSString*_Nonnull)comment {
    
    WalletID walletID(Zero);
    if (walletID.FromHex(to.string))
    {
        try{
            wallet->getAsync()->sendMoney(walletID, comment.string, amount * Rules::Coin,fee);
        }
        catch(NSException *ex) {
            NSLog(@"%@",ex);
        }
    }
}

#pragma mark - Logs

-(void)createLogger {
    NSString *dataPath = [Settings logPath];
    
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
    
    [SSZipArchive createZipFileAtPath:archivePath withContentsOfDirectory:[Settings logPath]];
    
    return archivePath;
}

#pragma mark - Transactions

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

#pragma mark - UTXO

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
    
@end
