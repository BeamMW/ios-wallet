//
//  DAOManager.m
//  BeamWallet
//
//  Created by Denis on 15.07.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

#import "DAOManager.h"
#include "wallet/api/i_wallet_api.h"
#include "wallet/core/common.h"


@implementation DAOManager {
    beam::wallet::IWalletApi::Ptr walletAPI;
}

+ (DAOManager*_Nonnull)sharedManager {
    static DAOManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

-(NSString*_Nonnull)generateAppID:(NSString*_Nonnull)name url:(NSString*_Nonnull)url {
//    ECC::Hash::Value hv;
//    ECC::Hash::Processor() << appName.string << appUrl.string >> hv;
//
//    auto appid = std::string("appid:") + hv.str();
    return @""; //[NSString stringWithUTF8String:appid.c_str()];
}



@end
