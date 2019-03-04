//
//  AppModel.m
//  BeamTest
//
//  Created by Denis on 2/28/19.
//  Copyright © 2019 Denis. All rights reserved.
//

#import <Foundation/Foundation.h>

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
    IWalletDB::Ptr walletDb;
    WalletModel::Ptr wallet;

    ECC::NoLeak<ECC::uintBig> passwordHash;
}

+ (AppModel*)sharedManager {
    static AppModel *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

-(id)init{
    self = [super init];
    
    return self;
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

//    auto addressess = walletDb->getAddresses(true);
//    auto wid = addressess[0].m_walletID;
//    auto s = to_string(wid);
//
//    NSString* result = [NSString stringWithUTF8String:s.c_str()];
//
//    NSLog(@"%@",result);



@end
