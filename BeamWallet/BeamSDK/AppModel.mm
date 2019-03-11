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
#import "StringStd.h"
#import "MnemonicModel.h"
#import "WalletModel.h"

#include "wallet/wallet.h"
#include "wallet/wallet_db.h"
#include "wallet/wallet_network.h"
#include "wallet/wallet_model_async.h"
#include "wallet/wallet_client.h"

#include "utility/bridge.h"
#include "utility/string_helpers.h"

#include "mnemonic/mnemonic.h"

#include "common.h"

using namespace beam;
using namespace ECC;
using namespace std;


@implementation AppModel  {
    Reachability *internetReachableFoo;

    IWalletDB::Ptr walletDb;
    WalletModel::Ptr wallet;

    ECC::NoLeak<ECC::uintBig> passwordHash;
    
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
    }
    _isConnected = isConnected;
}


-(BOOL)isWalletAlreadyAdded {
    return [[NSFileManager defaultManager] fileExistsAtPath:Settings.walletStoragePath];
}

-(BOOL)openWallet:(NSString*)pass {
    Rules::get().UpdateChecksum();

    string dbFilePath = Settings.walletStoragePath.string;

    if (!walletDb) {
        walletDb = WalletDB::open(dbFilePath, pass.string);
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

    walletDb = WalletDB::open(dbFilePath, pass.string);
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
    if (phrase.isEmpty || pass.isEmpty) {
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
    
    wallet = make_shared<WalletModel>(walletDb, nodeAddr);
    
    wallet->getAsync()->setNodeAddress(nodeAddr);
    
    wallet->start();
}


-(void)refreshWallet {
    wallet->getAsync()->refresh();
}

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
        [self getNetworkStatus];
    }
}

//TODO: TMP Solution
-(NSString* _Nullable)getWalletFirstAddress {
    auto addresses = walletDb->getAddresses(true);
    
    return [NSString stringWithUTF8String:to_string(addresses[0].m_walletID).c_str()];
}

#pragma mark - Address

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
                addresses[i].m_duration = hours * 60 * 60;
                
                walletDb->saveAddress(addresses[i]);
                
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
                addresses[i].m_label = comment.string;
                
                walletDb->saveAddress(addresses[i]);
                
                break;
            }
        }
    }
}

-(void)generateNewWalletAddress {    
    wallet->getAsync()->generateNewAddress();
}

#pragma mark - Delegates

-(void)addDelegate:(id<WalletModelDelegate>) delegate{
    [_delegates addObject: delegate];
}

-(void)removeDelegate:(id<WalletModelDelegate>) delegate {
    [_delegates removeObject: delegate];
}

@end
