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

#include "wallet/core/wallet.h"
#include "wallet/core/wallet_db.h"
#include "wallet/core/wallet_network.h"
#include "wallet/client/wallet_model_async.h"
#include "wallet/client/wallet_client.h"
#include "wallet/core/default_peers.h"


@implementation DAOManager  {
    WebAPICreator webAPICreator;
}

-(id)init {
    self = [super init];

    webAPICreator = WebAPICreator()
    
    return self;
}

-(void)launchApp:(BMApp*)app {
    auto appId = webapiCreator.generateAppID(app.name, app.url);
}

@end


