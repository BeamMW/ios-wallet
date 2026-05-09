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
#import <MessageUI/MessageUI.h>
#import <AVFoundation/AVFoundation.h>
#import <NotificationCenter/NotificationCenter.h>
#import <UserNotifications/UserNotifications.h>
#import <SafariServices/SafariServices.h>
#import <WebKit/WebKit.h>

#import "Reachability.h"
#import "AppModel.h"
#import "MnemonicModel.h"
#import "WalletModel.h"
#import "StringStd.h"
#import "DAOManager.h"
#import "RecoveryProgress.h"

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
#include "utility/logger.h"
#include "utility/string_helpers.h"
#include "utility/fsutils.h"

#include "mnemonic/mnemonic.h"

#include "wallet/transactions/lelantus/unlink_transaction.h"
#include "wallet/transactions/lelantus/push_transaction.h"
#include "wallet/transactions/lelantus/pull_transaction.h"
#include "wallet/transactions/dex/dex_tx.h"

#include "wallet/core/simple_transaction.h"
#include "wallet/core/common_utils.h"
#include "wallet/core/common.h"
#include "common.h"
#include "sqlite3.h"
#include <sys/sysctl.h>
#include <mutex>

// beam::Rules::s_pInstance is declared thread_local in the header but its
// out-of-class definition is missing from the provided static libraries.
thread_local const beam::Rules* beam::Rules::s_pInstance = nullptr;
#import <sys/utsname.h>

#import "BeamWallet-Swift.h"
//#import "BeamWalletMasterNet-Swift.h"
//#import "BeamWalletTestNet-Swift.h"

using namespace beam;
using namespace ECC;
using namespace beam;
using namespace beam::io;
using namespace beam::wallet;
using namespace std;

static int proofSize = 330;
static NSString *transactionCommentsKey = @"transaction_commentNew";
static NSString *restoreFlowKey = @"restoreFlowKeyNew";
static NSString *currenciesKey = @"allCurrenciesKeyNew";
static NSString *unlinkAddressName = @"Unlink";
static NSString *walletStatusKey = @"walletStatusKeyNew";
static NSString *transactionsKey = @"transactionsKeyNew";
static NSString *notificationsKey = @"notificationsKeyNew";
static NSString *ignoredContactsKey = @"ignoredcontactsKeyNew";
static NSString *sendedNotificationsKey = @"sendedNotificationsKey";


const int kDefaultFeeInGroth = 10;
const int kFeeInGroth_Fork1 = 100;

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

typedef void(^GetMinConfirmationsBlock)(uint32_t count);

struct GetMinConfirmationsFunc
{
    GetMinConfirmationsBlock block;
    
    void operator() (uint32_t count){
        block(count);
    }
};

typedef void(^NewTokenGeneratedBlock)(std::string token);

struct NewTokenGeneratedFunc
{
    NewTokenGeneratedBlock block;
    
    void operator() (std::string token){
        block(token);
    }
};

static dispatch_once_t * once_token_model;

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
    ShieldedVoucherList lastVouchers;
    NSString *lastWalledId;
    std::string *lastWalledIdS;
    
    DAOManager *daoManager;
    DAOViewController *daoViewController;
    
    boost::optional<beam::wallet::WalletAddress> _receiverAddress;
    
    RecoveryProgress recoveryProgress;
}

+ (AppModel*_Nonnull)sharedManager {
    static AppModel *sharedMyManager = nil;
    
    static dispatch_once_t once_token;
    once_token_model = &once_token;
    
    dispatch_once(&once_token, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

-(void)didGenerateVauchers:(ShieldedVoucherList) v {
    
}

-(id)init{
    self = [super init];

    [self loadRules];

    [self createLogger];
        
    wallet::g_AssetsEnabled = true;
    
    reconnectAttempts = 0;
    reconnectNodes = [NSMutableArray new];
    lastWalledId = @"";
    
    
    walletReactor = Reactor::create();
    io::Reactor::Scope s(*walletReactor); // do it in main thread
    
    _delegates = [NSPointerArray weakObjectsPointerArray];
    
    _transactions = [[NSMutableArray alloc] init];

    _shildedUtxos = [[NSMutableArray alloc] init];
    _contacts = [[NSMutableArray alloc] init];
    _notifications = [[NSMutableArray alloc] init];
    _deletedNotifications = [[NSMutableDictionary alloc] init];
    _preparedTransactions = [[NSMutableArray alloc] init];
    _preparedDeleteAddresses = [[NSMutableArray alloc] init];
    _preparedDeleteTransactions = [[NSMutableArray alloc] init];
    _needSaveContacts = [[NSMutableDictionary alloc] init];
    
    _isRestoreFlow = [[NSUserDefaults standardUserDefaults] boolForKey:restoreFlowKey];
    _apps = [[NSMutableArray alloc] init];
    _chats = [[NSMutableArray alloc] init];
    _messagesByPeer = [[NSMutableDictionary alloc] init];
    _dexOrders = [[NSMutableArray alloc] init];
    
    NSData *dataStatus = [[NSUserDefaults standardUserDefaults] objectForKey:walletStatusKey];
    if(dataStatus != nil) {
        _walletStatus = [NSKeyedUnarchiver unarchivedObjectOfClass:BMWalletStatus.class fromData:dataStatus error:nil];
    }
    
    NSData *dataTransactions = [[NSUserDefaults standardUserDefaults] objectForKey:transactionsKey];
    if(dataTransactions != nil) {
        NSSet *classes = [NSSet setWithObjects:[NSArray class], [BMTransaction class], [BMAsset class],
                          [NSMutableString self], nil];
        NSError *error;
        _transactions = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:dataTransactions error:&error];
        NSLog(@"%@", error);
    }
    
    NSData *dataNotifications = [[NSUserDefaults standardUserDefaults] objectForKey:notificationsKey];
    if(dataNotifications != nil) {
        NSSet *classes = [NSSet setWithObjects:[NSArray class], [BMNotification class], nil];
        _notifications = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:dataTransactions error:nil];
    }
    
    if (_transactions == nil) {
        _transactions = [[NSMutableArray alloc] init];
        _shildedUtxos = [[NSMutableArray alloc] init];
        _contacts = [[NSMutableArray alloc] init];
        _deletedNotifications = [[NSMutableDictionary alloc] init];
        _preparedTransactions = [[NSMutableArray alloc] init];
        _preparedDeleteAddresses = [[NSMutableArray alloc] init];
        _preparedDeleteTransactions = [[NSMutableArray alloc] init];
    }
    
    if (_notifications == nil) {
        _notifications = [[NSMutableArray alloc] init];
    }
    
    [self checkInternetConnection];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];

    return self;
}


// Raw storage so we can publish s_pInstance before Rules::Rules() runs —
// the constructor calls Rules::get() internally and would throw otherwise.
static unsigned char g_rulesStorage[sizeof(beam::Rules)] __attribute__((aligned(__alignof__(beam::Rules))));

// Non-thread-local handle WalletModel.mm uses to install s_pInstance on worker threads.
beam::Rules* g_pConfiguredRules = nullptr;

static beam::Rules& getConfiguredRules() {
    static std::once_flag s_flag;
    std::call_once(s_flag, []() {
        beam::Rules* pRules = reinterpret_cast<beam::Rules*>(g_rulesStorage);
        beam::Rules::s_pInstance = pRules;
        new(pRules) beam::Rules();

        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if ([bundleID containsString:@"Masternet"] || [bundleID containsString:@"masternet"]) {
            pRules->m_Network = beam::Rules::Network::masternet;
        } else if ([bundleID containsString:@"Mainnet"] || [bundleID containsString:@"mainnet"]) {
            pRules->m_Network = beam::Rules::Network::mainnet;
        } else {
            pRules->m_Network = beam::Rules::Network::testnet;
        }
        pRules->SetNetworkParams();
        pRules->UpdateChecksum();
        g_pConfiguredRules = pRules;
    });
    return *reinterpret_cast<beam::Rules*>(g_rulesStorage);
}

-(void)loadRules{
    beam::Rules& rules = getConfiguredRules();
    beam::Rules::s_pInstance = &rules;  // Install on this thread (s_pInstance is thread_local)
    BEAM_LOG_INFO() << "Rules signature: " << rules.get_SignatureStr();
}

+(NSString*_Nonnull)chooseRandomNodeWithoutNodes:(NSArray*)nodes {
//    return @"eu-node02.masternet.beam.mw:8100";
    
    auto peers = getDefaultPeers();

    NSMutableArray *array = [NSMutableArray array];

    for (const auto& item : peers) {
        BOOL found = NO;
        NSString *address = [NSString stringWithUTF8String:item.c_str()];
        if ([address rangeOfString:@"shanghai"].location == NSNotFound
            && [address rangeOfString:@"raskul"].location == NSNotFound
            && [address rangeOfString:@"45."].location == NSNotFound) {
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

+(NSString*_Nonnull)chooseRandomNode {
    // Settings.init calls this class method before AppModel.init runs, so the
    // BEAM library hasn't been initialized yet — install Rules first.
    beam::Rules::s_pInstance = &getConfiguredRules();
    auto peers = getDefaultPeers();
    
    NSMutableArray *array = [NSMutableArray array];
    
    for (const auto& item : peers) {
        NSString *address = [NSString stringWithUTF8String:item.c_str()];
        if([address rangeOfString:@"shanghai"].location == NSNotFound
           && [address rangeOfString:@"raskul"].location == NSNotFound
           && [address rangeOfString:@"45."].location == NSNotFound) {
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
        NSError *error = nil;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:tr requiringSecureCoding:YES error:&error];
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:transactionsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    });
}

-(void)changeNotifications {
    NSMutableArray *notif = [NSMutableArray arrayWithArray:self->_notifications];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:notif requiringSecureCoding:YES error:&error];
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:notificationsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    });
}

#pragma mark - Status

-(void)setWalletStatus:(BMWalletStatus *)walletStatus {
    _walletStatus = walletStatus;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_walletStatus requiringSecureCoding:YES error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:walletStatusKey];
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
                NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
                for(id<WalletModelDelegate> delegate in delegates) {
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
        
        NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
        for(id<WalletModelDelegate> delegate in delegates)
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
    
    if (wallet != nil) {
        _isConfigured = wallet->isConnectionTrusted();
    }
}

-(void)setIsConnecting:(BOOL)isConnecting {
    _isConnecting = isConnecting;

    NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
    for(id<WalletModelDelegate> delegate in delegates)
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
            
            NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
            for(id<WalletModelDelegate> delegate in delegates)
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
    // BEAM 7.5.14432+ rejects WalletDB::open with SQLITE_MISUSE when the
    // current reactor has been scoped in/out previously (e.g. the one created
    // in AppModel.init). Drop and recreate so open runs against a fresh one.
    walletReactor.reset();
    walletReactor = Reactor::create();
    // Scope must outlive WalletDB::open so the reactor is registered as current
    // when the DB sets up its internal I/O callbacks (required in 7.5.14432+).
    io::Reactor::Scope s(*walletReactor);

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
        
    return YES;
}

-(BOOL)canOpenWallet:(NSString*)pass {
    // See openWallet: BEAM 7.5.14432+ requires a fresh reactor here.
    walletReactor.reset();
    walletReactor = Reactor::create();
    // Scope must outlive WalletDB::open so the reactor is registered as current
    // when the DB sets up its internal I/O callbacks (required in 7.5.14432+).
    io::Reactor::Scope s(*walletReactor);

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
    // DB init is purely local — do not gate on reachability. If the device is
    // offline the wallet is created locally and sync resumes when reachability
    // returns (Reachability already broadcasts onNoInternetConnection).
    if (walletDb != nil)
    {
        [self onWalledOpened:SecString(pass.string)];

        return YES;
    }
    
    string dbFilePath = [Settings sharedManager].walletStoragePath.string;

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

    // Reaching this code path means walletDb is nil and the user explicitly
    // chose to create a new wallet — any file on disk is stale (orphan from a
    // crashed prior attempt, or left over after a change-wallet that ran with
    // walletDb already nil). Unlink the file and sidecars so WalletDB::init
    // gets a clean slate.
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dbPath = [Settings sharedManager].walletStoragePath;
    [fm removeItemAtPath:dbPath error:nil];
    [fm removeItemAtPath:[dbPath stringByAppendingString:@".private"] error:nil];
    [fm removeItemAtPath:[dbPath stringByAppendingString:@"-wal"] error:nil];
    [fm removeItemAtPath:[dbPath stringByAppendingString:@"-shm"] error:nil];
    [fm removeItemAtPath:[dbPath stringByAppendingString:@"-journal"] error:nil];

    // BEAM's sqlite needs a writable temp dir; iOS sandbox blocks /tmp. Point
    // it at the app's NSTemporaryDirectory so CREATE TABLE / journaling has a
    // place to spill — otherwise WalletDB::init can fail with SQLITE_MISUSE.
    NSString *tmpDir = NSTemporaryDirectory();
    if (tmpDir.length > 0) {
        sqlite3_temp_directory = sqlite3_mprintf("%s", [tmpDir UTF8String]);
    }

    BEAM_LOG_INFO() << "createWallet preflight"
        << " path=" << dbFilePath
        << " fileExists=" << ([fm fileExistsAtPath:dbPath] ? 1 : 0)
        << " tmpdir=" << ((tmpDir.length > 0) ? [tmpDir UTF8String] : "(null)")
        << " rules=" << (beam::Rules::s_pInstance ? 1 : 0)
        << " seedSize=" << seed.size()
        << " sqliteVersion=" << sqlite3_libversion()
        << " sqliteHasCodec=" << (sqlite3_compileoption_used("SQLITE_HAS_CODEC") ? 1 : 0);

    // BEAM 7.5.14432: WalletDB::init must run under a current Reactor::Scope
    // so DB I/O callbacks bind to that reactor. Recreate, since the reactor
    // from AppModel.init has already been scoped in/out once.
    walletReactor.reset();
    walletReactor = Reactor::create();
    io::Reactor::Scope s(*walletReactor);

    try {
        walletDb = WalletDB::init(dbFilePath, SecString(pass.string), seed.hash());
    }
    catch (const std::exception& e) {
        BEAM_LOG_ERROR() << "WalletDB::init failed: " << e.what();
        walletDb.reset();
        return NO;
    }

    if (!walletDb) {
        return NO;
    }

    [self onWalledOpened:SecString(pass.string)];

    return YES;
}

-(void)abortCreateAndReset {
    self.isRestoreFlow = NO;
    [self resetWallet:YES];
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
    BEAM_LOG_INFO() << "restart wallet";
    
    isStarted = NO;
    isRunning = NO;
    
    if (wallet!=nil){
        wallet.reset();
    }
    
    if (walletDb!=nil){
        walletDb.reset();
    }
    
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

    [daoManager destroy];
    daoManager = nil;

    isStarted = NO;
    isRunning = NO;

    wallet.reset();

    walletDb.reset();

    if(removeDatabase) {
        NSString *dbPath = [Settings sharedManager].walletStoragePath;

        NSFileManager *fm = [NSFileManager defaultManager];
        [fm removeItemAtPath:[dbPath stringByAppendingString:@"-wal"] error:nil];
        [fm removeItemAtPath:[dbPath stringByAppendingString:@"-shm"] error:nil];
        [fm removeItemAtPath:[dbPath stringByAppendingString:@"-journal"] error:nil];

        fsutils::remove(dbPath.string);
        [fm removeItemAtPath:dbPath error:nil];

        [fm removeItemAtPath:[Settings sharedManager].localNodeStorage error:nil];
        [[Settings sharedManager] resetDataBase];

        [[OnboardManager shared] clearWalletInitialized];
    }
    
    _walletStatus = [BMWalletStatus new];
    [_transactions removeAllObjects];
    [_notifications removeAllObjects];
    [[AssetsManager.sharedManager assets] removeAllObjects];

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:notificationsKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:transactionsKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:walletStatusKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    [[Settings sharedManager] resetNode];
    
    *once_token_model = 0;
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
              NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
      for(id<WalletModelDelegate> delegate in delegates) {
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

    // Marker that distinguishes a healthy wallet from a DB file orphaned by
    // a crash mid-create. AppDelegate checks this on launch.
    [[OnboardManager shared] markWalletInitialized];

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

        // Caller dispatches us onto a background queue, so Rules::s_pInstance
        // (thread_local) isn't set on this thread yet — install it before any
        // BEAM API runs, otherwise WalletModel ctor / wallet->start() throw.
        [self loadRules];

        try{
            // Reactor must be current while WalletModel binds to walletDb,
            // otherwise the worker thread inherits no current reactor and
            // sqlite calls fail with SQLITE_MISUSE.
            if (walletReactor == nil) {
                walletReactor = Reactor::create();
            }
            io::Reactor::Scope reactorScope(*walletReactor);

            string nodeAddrStr = [Settings sharedManager].nodeAddress.string;

            auto pushTxCreator = std::make_shared<lelantus::PushTransaction::Creator>([=]() { return walletDb; });

            auto additionalTxCreators = std::make_shared<std::unordered_map<TxType, BaseTransaction::Creator::Ptr>>();
            additionalTxCreators->emplace(TxType::PushTransaction, pushTxCreator);

            wallet = make_shared<WalletModel>(walletDb, nodeAddrStr, walletReactor);
            
            NSLog(@"NODE ADDRESS: %@", [Settings sharedManager].nodeAddress);

            wallet->getAsync()->setNodeAddress(nodeAddrStr);
            
            if ([Settings sharedManager].isNodeProtocolEnabled) {
                [Settings sharedManager].isNodeProtocolEnabled = NO;
                wallet->getAsync()->enableBodyRequests(false);
            }
            
            wallet->start(activeNotifications, isSecondCurrencyEnabled, additionalTxCreators);

            __weak typeof(self) weakSelf = self;
            wallet->getAsync()->makeIWTCall([]() -> boost::any {
                if (!beam::Rules::s_pInstance && g_pConfiguredRules) {
                    beam::Rules::s_pInstance = g_pConfiguredRules;
                }
                return boost::any{};
            }, [weakSelf, recoveryPath](const boost::any&) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (strongSelf && strongSelf->wallet) {
                    strongSelf->wallet->getAsync()->importRecovery(recoveryPath);
                }
            });

            daoManager = [[DAOManager alloc] initWithWallet:wallet];
        }
        catch (const std::exception& e) {
            NSLog(@"ImportRecovery failed %s",e.what());
            
            NSString *erorString = [NSString stringWithUTF8String:e.what()];
            
                  NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
      for(id<WalletModelDelegate> delegate in delegates)
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
            
                  NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
      for(id<WalletModelDelegate> delegate in delegates)
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
        // Reactor must be current while WalletModel constructs and wallet->start()
        // runs, so DB callbacks bind to the same reactor walletDb was opened under.
        if (walletReactor == nil) {
            walletReactor = Reactor::create();
        }
        io::Reactor::Scope reactorScope(*walletReactor);

        try {
            string nodeAddrStr = [Settings sharedManager].nodeAddress.string;

            auto pushTxCreator = std::make_shared<lelantus::PushTransaction::Creator>([=]() { return walletDb; });
            auto additionalTxCreators = std::make_shared<std::unordered_map<TxType, BaseTransaction::Creator::Ptr>>();
            additionalTxCreators->emplace(TxType::PushTransaction, pushTxCreator);

            wallet = make_shared<WalletModel>(walletDb, nodeAddrStr, walletReactor);

            NSLog(@"NODE ADDRESS: %@", [Settings sharedManager].nodeAddress);

            wallet->getAsync()->setNodeAddress(nodeAddrStr);
            wallet->getAsync()->enableBodyRequests([Settings sharedManager].isNodeProtocolEnabled);
            wallet->start(activeNotifications, isSecondCurrencyEnabled, additionalTxCreators);

            // Install Rules::s_pInstance on the reactor's worker thread as the
            // first queued op so DB callbacks find a valid Rules pointer.
            wallet->getAsync()->makeIWTCall([]() -> boost::any {
                if (!beam::Rules::s_pInstance && g_pConfiguredRules) {
                    beam::Rules::s_pInstance = g_pConfiguredRules;
                }
                return boost::any{};
            }, [](const boost::any&){});

            isRunning = YES;
            isStarted = YES;

            daoManager = [[DAOManager alloc] initWithWallet:wallet];
        }
        catch (const std::exception& e) {
            BEAM_LOG_ERROR() << "AppModel.start failed: " << e.what();
            wallet.reset();
            isRunning = NO;
            isStarted = NO;
        }
    }
    else if(self.isConnected && isStarted && walletDb != nil && self.isInternetAvailable) {
        // No-op: previously broadcast onSyncProgressUpdated:0 total:0, which
        // progress UIs interpret as "starting over" and reset their bars.
        // Callers that need a fresh status should use getWalletStatus.
    }
    else if(wallet != nil)
    {
        if(self.isInternetAvailable && isRunning == NO && ![[Settings sharedManager] isLocalNode])
        {
            isRunning = YES;
            
//            auto additionalTxCreators = std::make_shared<std::unordered_map<TxType, BaseTransaction::Creator::Ptr>>();
//            additionalTxCreators->emplace(TxType::DexSimpleSwap, std::make_shared<DexTransaction::Creator>(walletDb));

            auto pushTxCreator = std::make_shared<lelantus::PushTransaction::Creator>([=]() { return walletDb; });
            auto additionalTxCreators = std::make_shared<std::unordered_map<TxType, BaseTransaction::Creator::Ptr>>();
            additionalTxCreators->emplace(TxType::PushTransaction, pushTxCreator);
            
            if ([Settings sharedManager].isNodeProtocolEnabled) {
                wallet->getAsync()->enableBodyRequests(true);
            }
            
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
            NSLog(@"NODE ADDRESS: %@", [Settings sharedManager].nodeAddress);
            self->wallet->getAsync()->setNodeAddress(nodeAddrStr);
        });
    }
}

-(BOOL)isMyAddress:(NSString*_Nullable)address identity:(NSString*_Nullable)identity {
    if ([self isToken:address])
    {
        BMTransactionParameters *params = [self getTransactionParameters:address];
        address = params.address;
    }
    
    for (BMAddress *add in _walletAddresses) {
        if ([add.walletId isEqualToString:address] || [add.identity isEqualToString:identity]) {
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
        [self getMinConfirmations];
        [self getMaxPrivacyLock];
    }
}

-(void)getMaxPrivacyLock {
    auto func = GetMaxPrivacyLockFunc();
    func.block = ^(uint8_t lock) {
        [Settings sharedManager].lockMaxPrivacyValue = lock;
    };
    
    wallet->getAsync()->getMaxPrivacyLockTimeLimitHours(func);
}

-(void)setMinConfirmations:(uint32_t)count {
    [Settings sharedManager].minConfirmations = count;
    wallet->getAsync()->setCoinConfirmationsOffset(count);
}

-(void)getMinConfirmations {
    auto func = GetMinConfirmationsFunc();
    func.block = ^(uint32_t count) {
        [Settings sharedManager].minConfirmations = count;
    };
    
    wallet->getAsync()->getCoinConfirmationsOffset(func);
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

-(void)refreshAddresses {
    wallet->getAsync()->getAddresses(true);
    wallet->getAsync()->getAddresses(false);
}

-(void)refreshContacts {
    wallet->getAsync()->getAddresses(false);
}

-(void)refreshTransactions {
    wallet->getAsync()->getTransactions();
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


-(void)generateWithdrawAddress:(NewAddressGeneratedBlock _Nonnull )block {

    self.generatedNewAddressBlock = block;
    
    for (int i=0; i<_walletAddresses.count; i++) {
        if ([_walletAddresses[i].label isEqualToString:@"Beam Runner"]
            && _walletAddresses[i].duration == 0
            && !_walletAddresses[i].isExpired) {
            [AppModel sharedManager].generatedNewAddressBlock(_walletAddresses[i], nil);
            return;
        }
    }
    
    if (wallet!=nil) {
        wallet->getAsync()->generateNewAddress();
    }
}


-(void)generateOfflineAddress:(NSString*_Nonnull)walletId assetId:(int)assetId amount:(double)amount result:(PublicAddressBlock _Nonnull)block {
    
    if (wallet!=nil) {
        uint32_t bAsset = (uint32_t)assetId;
        uint64_t bAmount = round(amount * Rules::Coin);
        
        auto func = NewTokenGeneratedFunc();
        func.block = ^(std::string token) {
            NSString *sToken = [NSString stringWithUTF8String:token.c_str()];
            block(sToken);
        };
        wallet->getAsync()->generateToken(TokenType::Offline, bAmount, bAsset, std::string(BEAM_LIB_VERSION), false, func);
    }
    
//    uint32_t bAsset = (uint32_t)assetId;
//    uint64_t bAmount = round(amount * Rules::Coin);
//
//    WalletID m_walletID(Zero);
//    m_walletID.FromHex(walletId.string);
//
//    auto address = walletDb->getAddress(m_walletID);
//    auto lastVouchers = GenerateVoucherList(walletDb->get_KeyKeeper(), address->m_OwnID, 1);
//
//    TxParameters offlineParameters;
//    offlineParameters.SetParameter(TxParameterID::TransactionType, beam::wallet::TxType::PushTransaction);
//    offlineParameters.SetParameter(TxParameterID::ShieldedVoucherList, lastVouchers);
//    offlineParameters.SetParameter(TxParameterID::PeerAddr, address->m_BbsAddr);
//    offlineParameters.SetParameter(TxParameterID::PeerEndpoint, address->m_Endpoint);
//    offlineParameters.SetParameter(TxParameterID::IsPermanentPeerID, true);
//    offlineParameters.SetParameter(TxParameterID::AssetID, beam::Asset::ID(bAsset));
//    if (bAmount > 0) {
//        offlineParameters.SetParameter(TxParameterID::Amount, bAmount);
//    }
//    auto token = to_string(offlineParameters);
//    block([NSString stringWithUTF8String:token.c_str()]);
    
    
}

-(NSString*_Nonnull)generateRegularAddress:(NSString*_Nonnull)walletId assetId:(int)assetId amount:(double)amount isPermanentAddress:(BOOL)isPermanentAddress {
        
    WalletID m_walletID(Zero);
    m_walletID.FromHex(walletId.string);
    
    uint32_t bAsset = (uint32_t)assetId;
    uint64_t bAmount = round(amount * Rules::Coin);
    auto address = walletDb->getAddress(m_walletID);
    auto regularAddress = GenerateRegularNewToken(*address, bAmount, bAsset, std::string(BEAM_LIB_VERSION));
    return [NSString stringWithUTF8String:regularAddress.c_str()];
}


-(void)generateMaxPrivacyAddress:(NSString*_Nonnull)walletId assetId:(int)assetId amount:(double)amount result:(PublicAddressBlock _Nonnull)block {
    if (wallet!=nil) {
        uint32_t bAsset = (uint32_t)assetId;
        uint64_t bAmount = round(amount * Rules::Coin);
        
        auto func = NewTokenGeneratedFunc();
        func.block = ^(std::string token) {
            NSString *sToken = [NSString stringWithUTF8String:token.c_str()];
            block(sToken);
        };
        wallet->getAsync()->generateToken(TokenType::MaxPrivacy, bAmount, bAsset, std::string(BEAM_LIB_VERSION), false, func);
    }
//    uint64_t bAmount = round(amount * Rules::Coin);
//    uint32_t bAsset = (uint32_t)assetId;
//
//    WalletID m_walletID(Zero);
//    m_walletID.FromHex(walletId.string);
//
//    WalletAddress address = *walletDb->getAddress(m_walletID);
//    auto maxPrivacyAddress = GenerateMaxPrivacyToken(address, *walletDb, bAmount, bAsset, std::string(BEAM_LIB_VERSION));
//    block([NSString stringWithUTF8String:maxPrivacyAddress.c_str()]);
}

-(void)getAssetInfoAsync:(int)assetId {
    wallet->getAsync()->getAssetInfo((uint)assetId);
}

-(void)loadFullAssetsList {
    if (wallet == nullptr) return;
    wallet->getAsync()->loadFullAssetsList();
}


#pragma mark - Addresses

-(BOOL)isAddress:(NSString*_Nullable)address {
    if (address==nil) {
        return NO;
    }
    return beam::wallet::CheckReceiverAddress(address.string);
}



-(BOOL)isExpiredAddress:(NSString*_Nullable)address {
    BMAddress *addr = [self findAddressByID:address];
    if (addr != nil && addr.isContact == NO && [addr isExpired]) {
        return YES;
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

}

-(void)setExpires:(int)hours toAddress:(NSString*)address {
    WalletID walletID(Zero);
    if (walletID.FromHex(address.string))
    {
        std::vector<WalletAddress> addresses = wallet->ownAddresses;
        
        for (int i=0; i<addresses.size(); i++)
        {
            NSString *wAddress = [NSString stringWithUTF8String:to_string(addresses[i].m_BbsAddr).c_str()];
            
            if ([wAddress isEqualToString:address])
            {
                try{
                    wallet->getAsync()->updateAddress(walletID, addresses[i].m_label, hours == 0 ? WalletAddress::ExpirationStatus::Never : WalletAddress::ExpirationStatus::Auto);
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


-(void)setContactComment:(NSString*)comment toAddress:(NSString*_Nonnull)address {
    WalletID walletID(Zero);
    if (walletID.FromHex(address.string))
    {
        std::vector<WalletAddress> addresses = wallet->contacts;
        
        for (int i=0; i<addresses.size(); i++)
        {
            NSString *wAddress = [NSString stringWithUTF8String:to_string(addresses[i].m_BbsAddr).c_str()];
            
            if ([wAddress isEqualToString:address])
            {
                WalletAddress _address;
                _address.m_label = comment.string;
                _address.m_BbsAddr = walletID;
                _address.m_createTime = NSDate.date.timeIntervalSince1970;
                _address.m_Endpoint = addresses[i].m_Endpoint;

                try{
                    wallet->getAsync()->saveAddress(_address);
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

-(void)setAddressName:(NSString*)comment toAddress:(NSString*_Nonnull)address {
    WalletID walletID(Zero);
    if (walletID.FromHex(address.string))
    {
        try{
            wallet->getAsync()->updateAddress(walletID, comment.string, WalletAddress::ExpirationStatus::Auto);
        }
        catch (const std::exception& e) {
            NSLog(@"setExpires failed");
        }
        catch (...) {
            NSLog(@"setExpires failed");
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
            NSString *wAddress = [NSString stringWithUTF8String:to_string(addresses[i].m_BbsAddr).c_str()];
            
            if ([wAddress isEqualToString:address])
            {
                try{
                    wallet->getAsync()->updateAddress(walletID, comment.string, addresses[i].m_duration == 0 ? WalletAddress::ExpirationStatus::Never : WalletAddress::ExpirationStatus::Auto);
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
                
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self->wallet->getAsync()->getAddresses(true);
            self->wallet->getAsync()->getAddresses(false);
        });
    }
    else if([self isToken:address]) {
        BMTransactionParameters *params = [[AppModel sharedManager] getTransactionParameters:address];

        if (walletID.FromHex(params.address.string)) {
            wallet->getAsync()->deleteAddress(walletID);
        }
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
            
            NSString *_id = _preparedDeleteAddresses[i]._id;
            if ([_id isEmpty] || _id == nil) {
                [[AppModel sharedManager] addIgnoredContact:address];
            }
            else {
                [[AppModel sharedManager] deleteAddress:_preparedDeleteAddresses[i]._id];
            }
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
        
        NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
        for(id<WalletModelDelegate> delegate in delegates)
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
    
    NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
    for(id<WalletModelDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(onWalletAddresses:)]) {
            [delegate onWalletAddresses:_walletAddresses];
        }
    }
    
    for(id<WalletModelDelegate> delegate in delegates)
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
        
        [self setAddressName:comment toAddress:address];
    }
    
}


-(void)generateNewWalletAddress {
    if (wallet!=nil) {
        wallet->getAsync()->generateNewAddress();
    }
}


-(void)generateNewWalletAddressWithBlockAndAmount:(int)assetId amount:(double)amount result:(NewAddressGeneratedBlock _Nonnull)block {
    self.generatedNewAddressBlock = block;

    if (wallet!=nil) {
        uint32_t bAsset = (uint32_t)assetId;
        uint64_t bAmount = round(amount * Rules::Coin);
        
        auto func = NewTokenGeneratedFunc();
        func.block = ^(std::string token) {
            [AppModel sharedManager].addressGeneratedID = @"";

            NSString *sToken = [NSString stringWithUTF8String:token.c_str()];
            auto pParams = beam::wallet::ParseParameters(token);

            BMAddress *address = [[BMAddress alloc] init];
            address.address = sToken;
            address.walletId = @"";
            address.label = @"";
            if (pParams)
            {
                beam::wallet::WalletID pid;
                if (pParams->GetParameter(beam::wallet::TxParameterID::PeerAddr, pid)) {
                    address.walletId = [NSString stringWithUTF8String:to_string(pid).c_str()];
                }
            }
            self.generatedNewAddressBlock(address, nil);

            self->wallet->getAsync()->getAddresses(true);
        };
        wallet->getAsync()->generateToken(TokenType::RegularNewStyle, bAmount, bAsset, std::string(BEAM_LIB_VERSION), false, func);
    }
}

-(void)generateNewWalletAddressWithBlock:(NewAddressGeneratedBlock _Nonnull )block{
    self.generatedNewAddressBlock = block;

    if (wallet!=nil) {
        uint64_t amount = 0;
        auto asset = beam::Asset::ID(0);
        auto func = NewTokenGeneratedFunc();
        func.block = ^(std::string token) {
            [AppModel sharedManager].addressGeneratedID = @"";

            NSString *sToken = [NSString stringWithUTF8String:token.c_str()];
            auto pParams = beam::wallet::ParseParameters(token);

            BMAddress *address = [[BMAddress alloc] init];
            address.address = sToken;
            address.walletId = @"";
            address.label = @"";
            if (pParams)
            {
                beam::wallet::WalletID pid;
                if (pParams->GetParameter(beam::wallet::TxParameterID::PeerAddr, pid)) {
                    address.walletId = [NSString stringWithUTF8String:to_string(pid).c_str()];
                }
            }
            self.generatedNewAddressBlock(address, nil);
        };

        wallet->getAsync()->generateToken(TokenType::RegularNewStyle, amount, asset, std::string(BEAM_LIB_VERSION), false, func);
//        wallet->getAsync()->generateNewAddress();
    }
}

-(void)getPublicAddress:(PublicAddressBlock _Nonnull )block {
    self.getPublicAddressBlock = block;
    wallet->getAsync()->getPublicAddress();
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

-(BOOL)hasActiveTransactionsFromAddress:(BMAddress*_Nonnull)address {
    NSMutableArray * array = [self getTransactionsFromAddress:address];
    
    for (BMTransaction *tr in array)
    {
        if (tr.enumStatus == BMTransactionStatusPending
            || tr.enumStatus == BMTransactionStatusRegistering
            || tr.enumStatus == BMTransactionStatusInProgress) {
            return YES;
        }
    }
    
    return NO;
}

-(NSMutableArray<BMTransaction*>*_Nonnull)getTransactionsFromAddress:(BMAddress*_Nonnull)address {
    
    NSMutableArray *result = [NSMutableArray array];
    NSArray * array = [NSArray arrayWithArray:self.transactions];
    
    for (BMTransaction *tr in array)
    {
        if ([tr.senderAddress isEqualToString:address.walletId]
            || [tr.receiverAddress isEqualToString:address.walletId]
            || ([tr.token isEqualToString:address.address] && tr.token.length > 1)) {
            [result addObject:tr];
        }
        else if([tr.receiverAddress isEqualToString:address._id] && !tr.receiverAddress.isEmpty) {
            [result addObject:tr];
        }
        else if([tr.receiverAddress isEqualToString: [address getSBBSAddress]] || [tr.senderAddress isEqualToString: [address getSBBSAddress]]) {
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
            || [tr.token isEqualToString:address.walletId]
            || [tr.senderAddress isEqualToString:address._id]
            || [tr.receiverAddress isEqualToString:address._id]
            || [tr.token isEqualToString:address._id]) {
            if (tr.enumStatus == BMTransactionStatusCancelled || tr.enumStatus == BMTransactionStatusCompleted || tr.enumStatus == BMTransactionStatusFailed)
            {
                [result addObject:tr];
            }
        }
    }
    
    return result;
}

-(void)saveToken:(NSString*_Nonnull)walletID token:(NSString*_Nonnull)token {
    WalletID m_walletID(Zero);
    m_walletID.FromHex(walletID.string);
    
    WalletAddress address = *walletDb->getAddress(m_walletID);
    _receiverAddress = address;
    _receiverAddress->m_Token = token.string;
    _receiverAddress->setExpirationStatus(beam::wallet::WalletAddress::ExpirationStatus::Auto);
    self->wallet->getAsync()->saveAddress(*_receiverAddress);
}

-(void)editAddress:(BMAddress*_Nonnull)address {
    BMContact *contact = [self getContactFromId:address.walletId];
        
    if(contact != nil)
    {
        WalletID walletID(Zero);
        if (walletID.FromHex(address._id.string))
        {
            bool isValid = false;
            auto buf = from_hex(contact.address.identity.string, &isValid);
            PeerID m_Endpoint = Blob(buf);
            
            WalletAddress _address;
            _address.m_label = address.label.string;
            _address.m_BbsAddr = walletID;
            _address.m_Token = address.address.string;
            _address.m_Endpoint = m_Endpoint;
            _address.m_createTime = NSDate.date.timeIntervalSince1970;
            walletDb->saveAddress(_address);
        }
        else {
            [self addContact:@"" address:address.address name:address.label identidy:address.identity];
        }
    }
    else{
        WalletID walletID(Zero);
        if (walletID.FromHex(address._id.string))
        {            
            auto status = beam::wallet::WalletAddress::ExpirationStatus::AsIs;
            
            if(address.isNowExpired) {
                status = beam::wallet::WalletAddress::ExpirationStatus::Expired;
            }
            else if(address.isNowActive) {
                if (address.isNowActiveDuration == 0){
                    status = beam::wallet::WalletAddress::ExpirationStatus::Never;
                }
                else{
                    status = beam::wallet::WalletAddress::ExpirationStatus::Auto;
                }
            }
            
            wallet->getAsync()->updateAddress(walletID, address.label.string,  status);
        }
    }
}

-(void)clearAllAddresses{
    for (BMAddress *add in _walletAddresses) {
        [self deleteAddress:add._id];
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

-(void)addIgnoredContact:(NSString*_Nonnull) addressId {
    if (![self containsIgnoredContact:addressId]) {
        NSMutableArray *array = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults]objectForKey:ignoredContactsKey]];
        [array addObject:addressId];
        
        [[NSUserDefaults standardUserDefaults] setObject:array forKey:ignoredContactsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

-(BOOL)containsIgnoredContact:(NSString*_Nonnull) addressId {
    NSMutableArray *array = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults]objectForKey:ignoredContactsKey]];
    
    for (int i=0; i<array.count; i++) {
        NSString *a = array[i];
        if([a isEqualToString:addressId]) {
            return YES;
        }
    }
    
    return NO;
}

-(void)addContact:(NSString*_Nonnull)addressId address:(NSString*_Nullable)address name:(NSString*_Nonnull)name  identidy:(NSString*_Nullable)identidy{

    if (name.length > 0) {
        [_needSaveContacts setObject:name forKey:addressId];
    }
    
    
    if(address != nil) {
        NSMutableArray *array = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults]objectForKey:ignoredContactsKey]];
        
        BOOL shouldSave = NO;
        for (int i=0; i<array.count; i++) {
            NSString *a = array[i];
            if([a isEqualToString:address]) {
                shouldSave = YES;
                [array removeObjectAtIndex:i];
                break;;
            }
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:array forKey:ignoredContactsKey];
        
        
        NSString *_identity = identidy;
        
        BMTransactionParameters *params = [[AppModel sharedManager] getTransactionParameters:address];
        
        if(_identity == nil) {
            _identity = params.identity;
        }

        WalletID walletID(Zero);
        walletID.FromHex(params.address.string);
            
        bool isValid = false;
        auto buf = from_hex(_identity.string, &isValid);
        PeerID m_Endpoint = Blob(buf);
        
        WalletAddress savedAddress;
        savedAddress.m_BbsAddr = walletID;
        savedAddress.m_createTime = getTimestamp();
        savedAddress.m_Endpoint = m_Endpoint;
        savedAddress.m_label = name.string;
        savedAddress.m_duration = WalletAddress::AddressExpirationNever;
        savedAddress.m_Token = address.string;
        wallet->getAsync()->saveAddress(savedAddress);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self->wallet->getAsync()->getAddresses(false);
        });
    }
    else {
        WalletID walletID(Zero);
        if (walletID.FromHex(addressId.string))
        {
            NSMutableArray *array = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults]objectForKey:ignoredContactsKey]];

            BOOL shouldSave = NO;
            for (int i=0; i<array.count; i++) {
                NSString *a = array[i];
                if([a isEqualToString:addressId]) {
                    shouldSave = YES;
                    [array removeObjectAtIndex:i];
                    break;;
                }
            }
            
            [[NSUserDefaults standardUserDefaults] setObject:array forKey:ignoredContactsKey];
            
            WalletAddress savedAddress;
            savedAddress.m_label = name.string;
            savedAddress.m_BbsAddr = walletID;
            if (identidy!=nil) {
                bool isValid = false;
                auto buf = from_hex(identidy.string, &isValid);
                PeerID m_Endpoint = Blob(buf);
                savedAddress.m_Endpoint = m_Endpoint;
                if(address != nil) {
                    savedAddress.m_Token = address.string;
                }
            }
            savedAddress.m_createTime = NSDate.date.timeIntervalSince1970;
           // walletDb->saveAddress(savedAddress);
            wallet->getAsync()->saveAddress(savedAddress);
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self->wallet->getAsync()->getAddresses(false);
            });
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
    if(ID.length != 0) {
        for (BMAddress *add in _walletAddresses.reverseObjectEnumerator) {
            if ([add.getMainId isEqualToString:ID] || [add.address isEqualToString:ID]) {
                return add;
            }
        }
        
        for (BMContact *contact in _contacts.reverseObjectEnumerator) {
            if ([contact.address.getMainId isEqualToString:ID] || [contact.address.address isEqualToString:ID]) {
                return contact.address;
            }
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

-(double)realTotal:(double)amount fee:(double)fee assetId:(int)assetId {
    Amount bAmount = round(amount * Rules::Coin);
    Amount bTotal = bAmount;
    if (assetId == 0) {
        bTotal = bTotal + fee;
    }
    double realAmount = double(int64_t(bTotal)) / Rules::Coin;
    return realAmount;
}

-(double)remaining:(double)amount fee:(double)fee assetId:(int)assetId {
    Amount available = [[AssetsManager sharedManager] getAsset:assetId].available;
    Amount bAmount = round(amount * Rules::Coin);
    Amount bTotal = bAmount;
    if (assetId == 0) {
        bTotal = bTotal + fee;
    }
    Amount remaining = available - bTotal;
    double realAmount = double(int64_t(remaining)) / Rules::Coin;
    return realAmount;
}

-(double)remainingBeam:(double)amount fee:(double)fee {
    Amount bAmount = round(amount * Rules::Coin);
    Amount bTotal = bAmount - fee;
    double realAmount = double(int64_t(bTotal)) / Rules::Coin;
    return realAmount;
}

-(NSString*_Nullable)canSend:(double)amount assetId:(int)assetId fee:(double)fee to:(NSString*_Nullable)to maxAmount:(double)maxAmount checkAddress:(BOOL)checkAddress {
    NSString *errorString = [self sendError:amount assetId:assetId fee:fee to:to checkAddress: checkAddress];
    if (errorString == nil) {
        if(maxAmount < 0) {
            NSString *amountString = @"0";
            NSString *assetName = [[[AssetsManager sharedManager] getAsset:assetId] unitName];
            NSString *fullName = [NSString stringWithFormat:@"%@ %@", amountString, assetName];
            return [NSString stringWithFormat:[@"max_funds_error" localized], fullName];
        }
        else if (amount > maxAmount && maxAmount != 0) {
            NSString *amountString = [[StringManager sharedManager] realAmountString:maxAmount];
            NSString *assetName = [[[AssetsManager sharedManager] getAsset:assetId] unitName];
            NSString *fullName = [NSString stringWithFormat:@"%@ %@", amountString, assetName];
            return [NSString stringWithFormat:[@"max_funds_error" localized], fullName];
        }
    }
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
    
    NSString *amountString = [CurrencyFormatter currencyFromNumber:[NSNumber numberWithDouble:need]];
    NSString *assetName = @"BEAM";
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", amountString, assetName];
    
    return [NSString stringWithFormat:[@"max_funds_error" localized], fullName];
}

-(void)calculateFee:(double)amount assetId:(int)assetId fee:(double)fee isShielded:(BOOL) isShielded result:(FeecalculatedBlock _Nonnull )block {
   
    self.isMaxPrivacyRequest = isShielded;

    self.feecalculatedBlock = block;
    
    Amount bAmount = round(amount * Rules::Coin);
    Amount bFee = fee;

    wallet->getAsync()->selectCoins(bAmount, bFee, beam::Asset::ID(assetId), isShielded);
   // wallet->getAsync()->calcShieldedCoinSelectionInfo(bAmount, 0, assetId, isShielded);
}

-(double)grothToBeam:(uint64_t)groth {
    double real = double(groth / Rules::Coin);
    return real;
}

-(NSString*)sendError:(double)amount assetId:(int)assetId fee:(double)fee checkMinAmount:(BOOL)check {
    
    Amount bAmount = round(amount * Rules::Coin);
    Amount bTotal = bAmount;
    if (assetId == 0) {
        bTotal = bAmount + fee;
    }
    Amount bMax = round(MAX_AMOUNT * Rules::Coin);
    BMAsset *asset = [[AssetsManager sharedManager] getAsset:assetId];
    Amount available = asset.available;
    
    if (amount==0) {
        return [@"amount_zero" localized];
    }
//    else if(available < bTotal)
//    {
//        double need = double(int64_t(bTotal - available)) / Rules::Coin;
//
//        NSString *beam = [CurrencyFormatter currencyFromNumber:[NSNumber numberWithDouble:need]];
//
//        NSString *s = [@"insufficient_funds" localized];
//        return [s stringByReplacingOccurrencesOfString:@"(value)" withString:[NSString stringWithFormat:@"%@ %@",beam, asset.unitName]];
//    }
    else if (bTotal > bMax)
    {
        NSString *beam = [CurrencyFormatter currencyFromNumber:[NSNumber numberWithDouble:MAX_AMOUNT]];
        
        return [NSString stringWithFormat:@"Maximum amount %@ %@", beam, asset.unitName];
    }
    
//    if (asset !=0 && self.walletStatus.available < fee) {
//        double need = double(int64_t(fee - self.walletStatus.available)) / Rules::Coin;
//        NSString *beam = [CurrencyFormatter currencyFromNumber:[NSNumber numberWithDouble:need]];
//        NSString *s = [@"insufficient_funds" localized];
//        return [s stringByReplacingOccurrencesOfString:@"(value)" withString:[NSString stringWithFormat:@"%@ %@",beam, @"BEAM"]];
//    }
    
    return nil;
}

-(NSString*)sendError:(double)amount assetId:(int)assetId fee:(double)fee to:(NSString*_Nullable)to checkAddress:(BOOL)checkAddress {
    NSString *error = [self sendError:amount assetId:assetId fee:fee checkMinAmount:NO];
    
    if (error!=nil) {
        return error;
    }
    else if(![self isValidAddress:to] && checkAddress)
    {
        return [@"incorrect_address" localized];
    }
    else{
        return nil;
    }
}



-(void)send:(double)amount fee:(double)fee assetId:(int)assetId to:(NSString*_Nonnull)to from:(NSString*_Nonnull)from comment:(NSString*_Nonnull)comment isOffline:(BOOL)isOffline {
        
    NSString *_id = to;
    BMAddress *contactAddress = [[AppModel sharedManager] findAddressByID:_id];
    NSString *_name = contactAddress.label;

    auto txParameters = beam::wallet::ParseParameters(to.string);
    if (!txParameters){
        return;
    }
    _txParameters = *txParameters;
    

    uint64_t bAmount = round(amount * Rules::Coin);
    uint64_t bfee = fee;
    
//    WalletID m_walletID(Zero);
//    m_walletID.FromHex(from.string);
    
    auto params = CreateSimpleTransactionParameters();
    const auto type = GetAddressType(to.string);
    
    auto messageString = comment.string;
    
    if (type == TxAddressType::MaxPrivacy || type == TxAddressType::PublicOffline || (type == TxAddressType::Offline && isOffline)) {
        if (!LoadReceiverParams(_txParameters, params, type)) {
            assert(false);
            return;
        }
        CopyParameter(TxParameterID::PeerID, _txParameters, params);
    }
    else {
        if(!LoadReceiverParams(_txParameters, params, TxAddressType::Regular)) {
            assert(false);
            return;
        }
    }

    //        .SetParameter(beam::wallet::TxParameterID::MyID, m_walletID)

    params.SetParameter(TxParameterID::Amount, bAmount)
        .SetParameter(TxParameterID::Fee, bfee)
        .SetParameter(TxParameterID::AssetID, beam::Asset::ID((uint32_t)assetId))
        .SetParameter(TxParameterID::Message, beam::ByteBuffer(messageString.begin(), messageString.end()));

    if (type == TxAddressType::MaxPrivacy) {
        uint64_t limit = 64;
        CopyParameter(TxParameterID::Voucher, _txParameters, params);
        params.SetParameter(TxParameterID::MaxPrivacyMinAnonimitySet, limit);
    }
    
//    if (!beam::wallet::CheckReceiverAddress(to.string)) {
//        params.SetParameter(TxParameterID::OriginalToken, to.string);
//    }
    
    params.SetParameter(TxParameterID::OriginalToken, to.string);
    
    wallet->getAsync()->startTransaction(std::move(params));
    
    if (contactAddress != nil) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[AppModel sharedManager] editAddress:contactAddress];
        });
    }
    
   [self refreshContacts];
}

void CopyParameter(beam::wallet::TxParameterID paramID, const beam::wallet::TxParameters& input, beam::wallet::TxParameters& dest)
{
    ByteBuffer buf;
    if (input.GetParameter(paramID, buf))
    {
        dest.SetParameter(paramID, buf);
    }
}

-(void)prepareSendNew:(double)amount fee:(double)fee assetId:(int)assetId to:(NSString*_Nonnull)to comment:(NSString*_Nonnull)comment contactName:(NSString*_Nonnull)contactName maxPrivacy:(BOOL)maxPrivacy {
    
//    BMPreparedTransaction *transaction = [[BMPreparedTransaction alloc] init];
//    transaction.fee = fee;
//    transaction.amount = amount;
//    transaction.address = to;
//    transaction.comment = comment;
//    transaction.date = [[NSDate date] timeIntervalSince1970];
//    transaction.ID = [NSString randomAlphanumericStringWithLength:10];
//    transaction.contactName = contactName;
//    transaction.maxPrivacy = maxPrivacy;
//
//    [_preparedTransactions addObject:transaction];
//
//          NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
 //     for(id<WalletModelDelegate> delegate in delegates)
//    {
//        if ([delegate respondsToSelector:@selector(onAddedPrepareTransaction:)]) {
//            [delegate onAddedPrepareTransaction:transaction];
//        }
//    }
}

-(void)prepareSend:(double)amount fee:(double)fee assetId:(int)assetId to:(NSString*_Nonnull)to comment:(NSString*_Nonnull)comment from:(NSString*_Nullable)from saveContact:(BOOL)saveContact isOffline:(BOOL)isOffline {
    
    BMPreparedTransaction *transaction = [[BMPreparedTransaction alloc] init];
    transaction.fee = fee;
    transaction.amount = amount;
    transaction.address = to;
    transaction.from = from;
    transaction.comment = comment;
    transaction.date = [[NSDate date] timeIntervalSince1970];
    transaction.ID = [NSString randomAlphanumericStringWithLength:10];
    transaction.saveContact = saveContact;
    transaction.isOffline = isOffline;
    transaction.assetId = assetId;

    [_preparedTransactions addObject:transaction];
    
    NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
      for(id<WalletModelDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(onAddedPrepareTransaction:)]) {
            [delegate onAddedPrepareTransaction:transaction];
        }
    }
}

-(NSString*_Nonnull)allAmount:(double)fee assetId:(int)assetId {
    Amount available = [[AssetsManager sharedManager] getAsset:assetId].available;
    if(assetId == 0) {
        available = available - fee;
    }
    if (available < 0 || available == 0) {
        available = 0;
    }
    double d = double(int64_t(available)) / Rules::Coin;
    
    NSString *allValue =  [CurrencyFormatter currencyFromNumber:[NSNumber numberWithDouble:d]];
    allValue = [allValue stringByReplacingOccurrencesOfString:@"," withString:@""];
    
    if ([allValue hasPrefix:@"."])
    {
        allValue = [NSString stringWithFormat:@"0%@",allValue];
    }
    
    return allValue;
}

-(BMAddressType)getAddressTypeFrom:(TxAddressType) type {
    switch (type) {
        case TxAddressType::PublicOffline:
            return BMAddressTypeOfflinePublic;
        case TxAddressType::MaxPrivacy:
            return BMAddressTypeMaxPrivacy;
        case TxAddressType::Offline:
            return BMAddressTypeShielded;
        case TxAddressType::Regular:
            return BMAddressTypeRegular;
        default:
            break;
    }
    
    return BMAddressTypeUnknown;
}

-(NSString*_Nonnull)getAddressTypeString:(BMAddressType)type {
    switch (type) {
        case BMAddressTypeOfflinePublic:
            return [@"public_offline_address" localized];
        case BMAddressTypeMaxPrivacy:
            return [@"max_privacy_address" localized];
        default:
            return [@"regular_address" localized];
    }
    return [@"regular_address" localized];
}

-(BMTransactionParameters*_Nonnull)getTransactionParameters:(NSString*_Nonnull)token {
    const auto adressType = GetAddressType(token.string);

    auto params = beam::wallet::ParseParameters(token.string);
    auto amount = params->GetParameter<Amount>(TxParameterID::Amount);
    auto type = params->GetParameter<TxType>(TxParameterID::TransactionType);
    auto vouchers = params->GetParameter<ShieldedVoucherList>(TxParameterID::ShieldedVoucherList);
    auto isPermanentAddress = params->GetParameter<BOOL>(TxParameterID::IsPermanentPeerID);
    auto storedType = params->GetParameter<TxAddressType>(TxParameterID::AddressType);

    BMTransactionParameters *p = [BMTransactionParameters new];
    p.amount = 0.0;
    p.isMaxPrivacy = type == TxType::PushTransaction;
    p.newAddressType = [self getAddressTypeFrom:adressType];
    
    auto gen = params->GetParameter<ShieldedTxo::PublicGen>(TxParameterID::PublicAddreessGen);
    if (gen)
    {
        p.isPublicOffline = true;
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
        auto s = std::to_base58(*walletIdentity);
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
            wallet->getAsync()->saveVouchers(trVouchers, *peerId);
            wallet->getAsync()->getAddress(*peerId);
        }
    }
    
    if (auto assetId = params->GetParameter<uint32_t>(TxParameterID::AssetID); assetId) {
        p.assetId = *assetId;
    }
    else {
        p.assetId = 0;
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
    
    
    static auto logger = beam::Logger::create(BEAM_LOG_LEVEL_DEBUG,BEAM_LOG_LEVEL_DEBUG,BEAM_LOG_LEVEL_DEBUG,@"beam_".string, dataPath.string);
    
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
    
    BEAM_LOG_INFO() << "Application has started";
    BEAM_LOG_INFO() << ios.string;
    BEAM_LOG_INFO() << model.string;
    BEAM_LOG_INFO() << modelID.string;
    BEAM_LOG_INFO() << appVersion.string;
    BEAM_LOG_INFO() << langCode.string;
    
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
    auto own = wallet->isConnectionTrusted();
    return own || [Settings sharedManager].isNodeProtocolEnabled;
}

-(BOOL)isSynced {
    if (wallet == nil) {
        return false;
    }
    return wallet->isSynced();
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
        info.assetId = paymentInfo.m_AssetID;

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
        info.assetId = shieldedPaymentInfo.m_AssetID;

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
    
    NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
    for(id<WalletModelDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(onAddedDeleteTransaction:)]) {
            [delegate onAddedDeleteTransaction:_preparedDeleteTransactions.lastObject];
        }
    }
    
    for(id<WalletModelDelegate> delegate in delegates)
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
            
            BMPreparedTransaction *transaction = _preparedTransactions[i];
            
            [[AppModel sharedManager] send:transaction.amount fee:transaction.fee assetId:transaction.assetId to:transaction.address from:transaction.from comment:transaction.comment isOffline: transaction.isOffline];
            
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
        wallet->getAsync()->getAllUtxosStatus();
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
    if(idValue.length != 0) {
        for (BMContact *contact in _contacts) {
            if([contact.address.walletId isEqualToString:idValue] || [contact.address.getMainId isEqualToString:idValue])
            {
                return contact;
            }
        }
    }
    return nil;
}

-(void)clearAllContacts{
    for (BMContact *contact in _contacts) {
        [self deleteAddress:contact.address._id];
    }
}


#pragma mark - Fork

-(BOOL)isFork {
    return true;
}

-(int)getDefaultFeeInGroth {
    return [self isFork] ? kFeeInGroth_Fork1 : kDefaultFeeInGroth;
}

-(int)getMinFeeInGroth {
    return [self isFork] ? kFeeInGroth_Fork1 : 0;
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
        BEAM_LOG_INFO() << "It seems that node is not up to date";
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
    
          NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
      for(id<WalletModelDelegate> delegate in delegates)
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
          NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
      for(id<WalletModelDelegate> delegate in delegates)
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



#pragma mark - Notifications

-(int)getUnreadNotificationsCount {
    int count = 0;
    
    NSMutableArray *notifications = [NSMutableArray arrayWithArray:AppModel.sharedManager.notifications];

    for (BMNotification *notification in notifications) {
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
    NSMutableArray *array = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults]objectForKey:sendedNotificationsKey]];

    for (BMNotification *notification in AppModel.sharedManager.notifications) {
        if(!notification.isSended) {
            notification.isSended = YES;
            
            [array addObject:notification.nId];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:array forKey:sendedNotificationsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)clearNotifications {
    [_notifications removeAllObjects];
}

-(void)readAllNotifications {
    NSMutableArray *notifications = [NSMutableArray arrayWithArray:_notifications];
    for (BMNotification *notification in notifications) {
        if(![notification isRead]) {
            [self readNotification: notification.nId];
        }
    }
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

-(void)resetEstimateProgress {
    recoveryProgress.OnResetSimpleProgress();
}

-(UInt64)getEstimateProgress:(UInt64)done total:(UInt64)total {
    return recoveryProgress.OnSimpleProgress(done, total);
}

-(void)rescan {
    wallet->getAsync()->rescan();
}

-(void)enableBodyRequests:(BOOL)value {
    wallet->getAsync()->enableBodyRequests(value);
    wallet->getAsync()->getNetworkStatus();

    [[Settings sharedManager] setIsNodeProtocolEnabled:value];
}

-(void)sendDAOApiResult:(NSString*_Nonnull)json {
    [daoViewController sendDAOApiResultWithJson:json];
}

-(void)approveContractInfo:(NSString*_Nonnull)json info:(NSString*_Nonnull)info
                   amounts:(NSString*_Nonnull)amounts {
    
    [daoViewController showConfirmDialogWithJson:json info:info amount:amounts];    
}

-(void)stopDAO {
    [daoManager stopApp];
}

-(void)startApp:(UIViewController*_Nonnull)controller app:(BMApp*)app {
    if (daoManager == nil) {
        daoManager = [[DAOManager alloc] initWithWallet:wallet];
    }

    BOOL isSupported = [daoManager appSupported:app];
    
    __weak typeof(self) weakSelf = self;

    if (isSupported) {
        [daoManager launchApp:app];
        
        daoViewController = [[DAOViewController alloc] init];
        daoViewController.app = app;
        daoViewController.onRejected = ^(NSString * _Nonnull json) {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf->daoManager contractInfoRejected:json];
        };
        daoViewController.onApproved = ^(NSString * _Nonnull json) {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf->daoManager contractInfoApproved:json];
        };
        daoViewController.onCallWalletApi = ^(NSString * _Nonnull json) {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf->daoManager callWalletApi:json];
        };
        [[controller navigationController] pushViewController:daoViewController animated:YES];
    }
}

-(void)startBeamXDaoApp:(UINavigationController*_Nonnull)controller app:(BMApp*_Nonnull)app {
    if (daoManager == nil) {
        daoManager = [[DAOManager alloc] initWithWallet:wallet];
    }
    
    BOOL isSupported = [daoManager appSupported:app];
    
    __weak typeof(self) weakSelf = self;
    
    if (isSupported) {
        [daoManager launchApp:app];
        
        daoViewController = [[DAOViewController alloc] init];
        daoViewController.app = app;
        daoViewController.onRejected = ^(NSString * _Nonnull json) {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf->daoManager contractInfoRejected:json];
        };
        daoViewController.onApproved = ^(NSString * _Nonnull json) {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf->daoManager contractInfoApproved:json];
        };
        daoViewController.onCallWalletApi = ^(NSString * _Nonnull json) {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf->daoManager callWalletApi:json];
        };
        
        [controller setViewControllers:@[daoViewController] animated:false];
    }
}

-(void)loadApps {
    __weak typeof(self) weakSelf = self;

    NSString *urlAsString = [Settings sharedManager].dAppUrl;
    
    NSCharacterSet *set = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSString *encodedUrlAsString = [urlAsString stringByAddingPercentEncodingWithAllowedCharacters:set];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    [[session dataTaskWithURL:[NSURL URLWithString:encodedUrlAsString]
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;

        if (!error) {
            // Success
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSError *jsonError;
                NSArray *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                
                if (jsonError == nil) {
                    if(strongSelf->daoManager != nil) {
                        [strongSelf->_apps removeAllObjects];
                        
                        for (NSDictionary *dct in jsonResponse) {
                            BMApp *app = [BMApp new];
                            [app setAPIResult:dct];
                            [app setIsSupported:[strongSelf->daoManager appSupported:app]];
                            if(app.icon == nil) {
                                app.icon = @"";
                            }
                            [strongSelf->_apps addObject:app];
                        }
                        
                        NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
                        for(id<WalletModelDelegate> delegate in delegates) {
                            if ([delegate respondsToSelector:@selector(onDAPPsLoaded)]) {
                                [delegate onDAPPsLoaded];
                            }
                        }
                    }
                }
            }
        } else {
            NSLog(@"error : %@", error.description);
        }
    }] resume];
}


-(BMApp*_Nonnull)votingApp {
    for(BMApp *bApp in self.apps) {
        if ([bApp.name isEqualToString:@"BeamX DAO Voting"]) {
            return bApp;
        }
    }
    
    BMApp *app = [BMApp new];
    app.name = @"BeamX DAO Voting";
    app.api_version = @"current";
    
    if ([Settings sharedManager].target == Testnet) {
        app.url = @"https://apps-testnet.beam.mw/app/dao-voting-app/index.html";
    }
    else if ([Settings sharedManager].target == Mainnet) {
        app.url = @"https://apps.beam.mw/app/dao-voting-app/index.html";
    }
    else {
        app.url = @"http://3.19.141.112:80/app-same-origin/dao-voting-app/index.html";
    }
    return app;
}

-(BMApp*_Nonnull)DAOBeamXApp {
    for(BMApp *bApp in self.apps) {
        if ([bApp.name isEqualToString:@"BeamX DAO"]) {
            return bApp;
        }
    }
    
    BMApp *app = [BMApp new];
    app.name = @"BeamX DAO";
    app.api_version = @"current";
    
    if ([Settings sharedManager].target == Testnet) {
        app.url = @"https://apps-testnet.beam.mw/app/dao-core-app/index.html";
    }
    else if ([Settings sharedManager].target == Mainnet) {
        app.url = @"https://apps.beam.mw/app/dao-core-app/index.html";
    }
    else {
        app.url = @"http://3.19.141.112:80/app/plugin-dao-core/index.html";
    }
    return app;
}

-(BMApp*_Nonnull)daoFaucetApp {
    for(BMApp *bApp in self.apps) {
        if ([bApp.name isEqualToString:@"BEAM Faucet"]) {
            return bApp;
        }
    }
    
    BMApp *app = [BMApp new];
    app.name = @"BEAM Faucet";
    app.api_version = @"current";
    
    if ([Settings sharedManager].target == Testnet) {
        app.url = @"https://apps-testnet.beam.mw/app/dao-core-app/index.html";
    }
    else if ([Settings sharedManager].target == Mainnet) {
        app.url = @"https://apps.beam.mw/app/plugin-faucet/index.html";
        app.icon = @"https://apps.beam.mw/app/plugin-faucet/appicon.svg";
    }
    else {
        app.url = @"http://3.19.141.112:80/app/plugin-dao-core/index.html";
    }
    return app;
}

-(BMApp*_Nonnull)daoGalleryApp {
    for(BMApp *bApp in self.apps) {
        if ([bApp.name isEqualToString:@"NFT Gallery"]) {
            return bApp;
        }
    }

    BMApp *app = [BMApp new];
    app.name = @"NFT Gallery";
    app.api_version = @"current";

    if ([Settings sharedManager].target == Testnet) {
        app.url = @"https://apps-testnet.beam.mw/app/dao-core-app/index.html";
    }
    else if ([Settings sharedManager].target == Mainnet) {
        app.url = @"https://apps.beam.mw/app/plugin-gallery/index.html";
        app.icon = @"https://apps.beam.mw/app/plugin-gallery/appicon.svg";
    }
    else {
        app.url = @"http://3.19.141.112:80/app/plugin-dao-core/index.html";
    }
    return app;
}

#pragma mark - Messenger

static bool parseMessengerWalletID(NSString *input, beam::wallet::WalletID &out) {
    if (input == nil || input.length == 0) return false;
    std::string s = input.string;
    if (out.FromHex(s)) return true;
    auto params = beam::wallet::ParseParameters(s);
    if (params) {
        beam::wallet::WalletID parsed;
        if (params->GetParameter(beam::wallet::TxParameterID::PeerAddr, parsed)) {
            out = parsed;
            return true;
        }
    }
    return false;
}

-(NSString*_Nonnull)resolvedPeerWalletId:(NSString*_Nonnull)peerWalletId {
    WalletID peerID;
    if (parseMessengerWalletID(peerWalletId, peerID)) {
        return [NSString stringWithUTF8String:to_string(peerID).c_str()];
    }
    return peerWalletId;
}

-(void)addChatStub:(NSString*_Nonnull)peerWalletId contactName:(NSString*_Nullable)contactName myWalletId:(NSString*_Nullable)myWalletId {
    NSString *resolved = [self resolvedPeerWalletId:peerWalletId];
    BOOL changed = NO;
    BMChat *existing = nil;
    for (BMChat *chat in self.chats) {
        if ([chat.peerWalletId isEqualToString:resolved]) {
            existing = chat;
            break;
        }
    }
    if (existing != nil) {
        if (contactName.length > 0 && existing.contactName.length == 0) {
            existing.contactName = contactName;
            changed = YES;
        }
        if (myWalletId.length > 0 && existing.myWalletId.length == 0) {
            existing.myWalletId = myWalletId;
            changed = YES;
        }
    } else {
        BMChat *chat = [[BMChat alloc] init];
        chat.peerWalletId = resolved;
        chat.contactName = contactName;
        chat.myWalletId = myWalletId;
        chat.hasUnread = NO;
        chat.lastMessagePreview = @"";
        chat.lastMessageTimestamp = (UInt64)[[NSDate date] timeIntervalSince1970];
        [self.chats insertObject:chat atIndex:0];
        changed = YES;
    }
    if (changed) {
        NSArray *delegates = self.delegates.allObjects;
        for (id<WalletModelDelegate> delegate in delegates) {
            if ([delegate respondsToSelector:@selector(onChatListChanged)]) {
                [delegate onChatListChanged];
            }
        }
    }
}

-(void)requestChats {
    if (wallet == nil) return;
    wallet->getAsync()->getChats();
}

-(void)requestMessagesForPeer:(NSString*_Nonnull)peerWalletId {
    if (wallet == nil) return;
    WalletID peerID;
    if (!parseMessengerWalletID(peerWalletId, peerID)) return;
    wallet->getAsync()->getInstantMessages(peerID);
}

-(void)sendInstantMessage:(NSString*_Nonnull)peerWalletId
              fromAddress:(NSString*_Nonnull)myWalletId
                  message:(NSString*_Nonnull)message {
    if (wallet == nil) {
        NSLog(@"[Messenger] sendInstantMessage skipped — wallet not running");
        return;
    }
    WalletID peerID;
    WalletID myID;
    if (!parseMessengerWalletID(peerWalletId, peerID)) {
        NSLog(@"[Messenger] sendInstantMessage failed to parse peer=%@", peerWalletId);
        return;
    }
    if (!parseMessengerWalletID(myWalletId, myID)) {
        NSLog(@"[Messenger] sendInstantMessage failed to parse my=%@", myWalletId);
        return;
    }

    std::string text = message.string;
    ByteBuffer buffer(text.begin(), text.end());
    NSLog(@"[Messenger] sendInstantMessage peer=%@ from=%@ len=%lu", peerWalletId, myWalletId, (unsigned long)text.length());
    wallet->getAsync()->sendInstantMessage(peerID, myID, std::move(buffer));
}

-(void)markChatAsRead:(NSString*_Nonnull)peerWalletId {
    if (wallet == nil) return;
    WalletID peerID;
    if (!parseMessengerWalletID(peerWalletId, peerID)) return;

    NSString *resolved = [NSString stringWithUTF8String:to_string(peerID).c_str()];
    std::vector<std::pair<Timestamp, WalletID>> ims;
    NSArray<BMInstantMessage*> *cached = self.messagesByPeer[resolved];
    for (BMInstantMessage *msg in cached) {
        if (msg.isIncome && !msg.isRead) {
            ims.push_back(std::make_pair((Timestamp)msg.timestamp, peerID));
            msg.isRead = YES;
        }
    }
    if (!ims.empty()) {
        wallet->getAsync()->markIMsasRead(std::move(ims));
    }

    for (BMChat *chat in self.chats) {
        if ([chat.peerWalletId isEqualToString:resolved]) {
            chat.hasUnread = NO;
        }
    }
}

-(void)removeChat:(NSString*_Nonnull)peerWalletId {
    if (wallet == nil) return;
    WalletID peerID;
    if (!parseMessengerWalletID(peerWalletId, peerID)) return;
    wallet->getAsync()->removeChat(peerID);
}

-(NSArray<BMInstantMessage*>*_Nonnull)cachedMessagesForPeer:(NSString*_Nonnull)peerWalletId {
    NSString *resolved = [self resolvedPeerWalletId:peerWalletId];
    NSArray<BMInstantMessage*> *messages = self.messagesByPeer[resolved];
    return messages ?: @[];
}

-(NSString*_Nullable)lastMyAddressForPeer:(NSString*_Nonnull)peerWalletId {
    NSString *resolved = [self resolvedPeerWalletId:peerWalletId];
    NSArray<BMInstantMessage*> *messages = self.messagesByPeer[resolved];
    for (BMInstantMessage *msg in messages.reverseObjectEnumerator) {
        if (!msg.isIncome && msg.myWalletId.length > 0) {
            return msg.myWalletId;
        }
    }
    for (BMInstantMessage *msg in messages) {
        if (msg.myWalletId.length > 0) {
            return msg.myWalletId;
        }
    }
    return nil;
}

#pragma mark - Asset Swaps (DEX)

-(void)requestDexOrders {
#ifdef BEAM_ASSET_SWAP_SUPPORT
    if (wallet == nil) return;
    wallet->getAsync()->getDexOrders();
#endif
}

-(BOOL)publishDexOrderWithSendAsset:(UInt32)sendAssetId
                         sendAmount:(UInt64)sendAmount
                       receiveAsset:(UInt32)receiveAssetId
                      receiveAmount:(UInt64)receiveAmount
                  expirationMinutes:(UInt32)expirationMinutes {
#ifdef BEAM_ASSET_SWAP_SUPPORT
    if (wallet == nil || walletDb == nil) {
        NSLog(@"[AssetSwap] publishDexOrder skipped — wallet not running");
        return NO;
    }
    if (sendAmount == 0 || receiveAmount == 0 || sendAssetId == receiveAssetId) {
        return NO;
    }

    static const UInt32 kMaxExpirationMinutes = 720; // 12h — SBBS message TTL
    if (expirationMinutes == 0 || expirationMinutes > kMaxExpirationMinutes) {
        expirationMinutes = kMaxExpirationMinutes;
    }

    BMAsset *sendAsset = [[AssetsManager sharedManager] getAsset:(int)sendAssetId];
    BMAsset *receiveAsset = [[AssetsManager sharedManager] getAsset:(int)receiveAssetId];
    std::string sendSname = sendAsset.unitName.length > 0 ? sendAsset.unitName.string : "";
    std::string receiveSname = receiveAsset.unitName.length > 0 ? receiveAsset.unitName.string : "";

    WalletAddress sbbsAddress;
    sbbsAddress.m_label = "asset_swap";
    walletDb->createAddress(sbbsAddress);
    sbbsAddress.m_duration = WalletAddress::AddressExpiration24h;
    walletDb->saveAddress(sbbsAddress);

    DexOrder order(DexOrderID::generate(),
                   sbbsAddress.m_BbsAddr,
                   sbbsAddress.m_OwnID,
                   (Asset::ID)sendAssetId,
                   (Amount)sendAmount,
                   sendSname,
                   (Asset::ID)receiveAssetId,
                   (Amount)receiveAmount,
                   receiveSname,
                   expirationMinutes * 60);

    wallet->getAsync()->publishDexOrder(order);
    return YES;
#else
    return NO;
#endif
}

-(void)cancelDexOrderWithID:(NSString*_Nonnull)hexOrderID {
#ifdef BEAM_ASSET_SWAP_SUPPORT
    if (wallet == nil) return;
    DexOrderID orderId;
    if (!orderId.FromHex(hexOrderID.string)) return;
    wallet->getAsync()->cancelDexOrder(orderId);
#endif
}

-(BOOL)acceptDexOrder:(BMDexOrder*_Nonnull)order {
#ifdef BEAM_ASSET_SWAP_SUPPORT
    if (wallet == nil) return NO;

    WalletID peerID(Zero);
    if (!peerID.FromHex(order.sbbsID.string)) {
        return NO;
    }
    DexOrderID orderId;
    if (!orderId.FromHex(order.orderID.string)) {
        return NO;
    }

    Amount fee = (Amount)[self getDefaultFeeInGroth];

    auto params = CreateDexTransactionParams(
        orderId,
        peerID,
        (Asset::ID)order.receiveAssetId,
        (Amount)order.receiveAmount,
        (Asset::ID)order.sendAssetId,
        (Amount)order.sendAmount,
        fee);

    wallet->getAsync()->startTransaction(std::move(params));
    return YES;
#else
    return NO;
#endif
}

@end
