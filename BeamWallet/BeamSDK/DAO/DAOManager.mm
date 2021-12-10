//
//  DAOManager.m
//  BeamWallet
//
//  Created by Denis on 01.09.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

#import "DAOManager.h"
#import "AppsApiUI.h"
#import "Public.h"
#import "WebAPICreator.h"
#import "StringStd.h"

#include "common.h"

#include <sys/sysctl.h>
#import <sys/utsname.h>

#include "wallet/core/wallet.h"
#include "wallet/core/wallet_db.h"
#include "wallet/core/wallet_network.h"
#include "wallet/client/wallet_model_async.h"
#include "wallet/client/wallet_client.h"
#include "wallet/core/default_peers.h"


@implementation DAOManager  {
    WebAPICreator webAPICreator;
}

- (id)initWithWallet:(WalletModel::Ptr)wallet {
    self = [super init];
        
    webAPICreator = WebAPICreator();
    webAPICreator._walletModel = wallet;
    
    return self;
}

-(BOOL)appSupported:(BMApp*_Nonnull)app {
    return webAPICreator.apiSupported(app.api_version.string) || webAPICreator.apiSupported(app.min_api_version.string);
}

-(void)stopApp {
  //  webAPICreator._api.~shared_ptr();
    webAPICreator._api.reset();
//    webAPICreator._api = nil;
//
//    webAPICreator = nil;
    
//    webAPICreator._api.~shared_ptr();
   // webAPICreator.~WebAPICreator();
}

-(void)launchApp:(BMApp*_Nonnull)app {
    
    auto appId = webAPICreator.generateAppID(app.name.string, app.url.string);
    
    try
    {
        auto verWant = "current";
        auto verMin  = "";
        webAPICreator.createApi(verWant, verMin, app.name.string, app.url.string);
    }
    catch (NSException *ex)
    {
        NSLog(@"%@", ex);
    }
}

-(void)callWalletApi:(NSString*_Nonnull)json {
    if(webAPICreator._api != nil) {
        webAPICreator._api->callWalletApi(json.string);
    }
}

-(void)contractInfoApproved:(NSString*_Nonnull)json {
    if(webAPICreator._api != nil) {
        webAPICreator._api->contractInfoApproved(json.string);
    }
}

-(void)contractInfoRejected:(NSString*_Nonnull)json {
    if(webAPICreator._api != nil) {
        webAPICreator._api->contractInfoRejected(json.string);
    }
}

@end


