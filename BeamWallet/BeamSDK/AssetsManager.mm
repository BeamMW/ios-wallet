//
// AssetsManager.m
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

#import "AssetsManager.h"
#import "Settings.h"
#import "AppModel.h"
#include "wallet/core/wallet.h"

static NSString *assetsKey = @"assetsKeyNew_011";

NSArray *colors = @[@"#72fdff",@"#2acf1d",@"#ffbb54",@"#d885ff",@"#008eff",@"#ff746b",@"#91e300",@"#ffe75a",@"#9643ff",@"#395bff",@"#ff3b3b",@"#73ff7c",@"#ffa86c",@"#ff3abe",@"#00aee1",@"#ff5200",@"#6464ff",@"#ff7a21",@"#63afff",@"#c81f68"];

@implementation AssetsManager


+ (AssetsManager*_Nonnull)sharedManager {
    static AssetsManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

-(id)init{
    self = [super init];
    
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:assetsKey];
    if(data != nil) {
        NSSet *classes = [NSSet setWithObjects:[NSArray class], [BMAsset class], nil];
        _assets = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:nil];
    }
    
    if (_assets == nil || _assets.count == 0) {
        _assets = [[NSMutableArray alloc] init];
        
        BMAsset *asset = [[BMAsset alloc] init];
        asset.assetId = 0;
        asset.nthUnitName = @"BEAM";
        asset.unitName = @"BEAM";
        asset.color = @"#00F6D2";
        asset.shortName = @"BEAM";
        asset.shortDesc = @"";
        asset.longDesc = @"";
        asset.site = @"";
        asset.paper = @"";
        [_assets addObject:asset];
        
        BMAsset *beamX = [[BMAsset alloc] init];
        if ([Settings.sharedManager target] == Masternet) {
            beamX.assetId = 31;
        }
        else if ([Settings.sharedManager target] == Testnet) {
            beamX.assetId = 12;
        }
        else {
            beamX.assetId = 7;
        }
        beamX.nthUnitName = @"BEAMX";
        beamX.unitName = @"BEAMX";
        beamX.color = @"#977dff";
        beamX.shortName = @"BEAMX";
        beamX.shortDesc = @"BeamX DAO governance token";
        beamX.longDesc = @"BEAMX token is a Confidential Asset issued on top of the Beam blockchain with a fixed emission of 100,000,000 units (except for the lender of a \"last resort\" scenario). BEAMX is the governance token for the BeamX DAO, managed by the BeamX DAO Core contract. Holders can earn BeamX tokens by participating in the DAO activities: providing liquidity to the DeFi applications governed by the DAO or participating in the governance process.";
        beamX.site = @"https://www.beamxdao.org/";
        beamX.paper = @"https://documentation.beam.mw/overview/beamx-tokenomics";
        [_assets addObject:beamX];
    }
    
    return self;
}

-(NSString*_Nonnull)getAssetColor:(int)value {
    if(value == 3 && [Settings.sharedManager target] == Masternet) {
        return @"#977dff";
    }
    else if(value == 12 && [Settings.sharedManager target] == Testnet) {
        return @"#977dff";
    }
    else if (value == 7 && [Settings.sharedManager target] == Mainnet) {
        return @"#977dff";
    }
    int idx = (value % colors.count);
    return colors[idx];
}

-(BMAsset*_Nullable)getAsset:(int)assetId {
    for (BMAsset *asset in self.assets.reverseObjectEnumerator) {
        if (asset.assetId == assetId) {
            return asset;
        }
    }
    
    [[AppModel sharedManager] getAssetInfoAsync:assetId];

    return nil;
}

-(BMAsset*_Nullable)getAssetByName:(NSString*_Nullable)name {
    for (BMAsset *asset in self.assets.reverseObjectEnumerator) {
        if ([asset.unitName isEqualToString:name]) {
            return asset;
        }
    }
    return nil;
}

-(BMTransaction*_Nullable)getLastTransaction:(int)assetId {
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdTime"
                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray = [[AppModel sharedManager].transactions sortedArrayUsingDescriptors:sortDescriptors];
    
    for (BMTransaction *transaction in sortedArray) {
        if (transaction.assetId == assetId) {
            return transaction;
        }
    }
    return nil;
}

-(void)changeAssets {
    @try {
        NSMutableArray *notif = [NSMutableArray arrayWithArray:self->_assets];
        NSError *error = nil;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:notif requiringSecureCoding:YES error:&error];
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:assetsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    @catch (NSException *exception) {

    }
    @finally {
    }
}

-(double)getRealAvailableAmount:(int)assetId {
    BMAsset *asset = [self getAsset:assetId];
    return asset.realAmount;
}

-(NSMutableArray<BMAsset*>*_Nonnull)getAssetsWithBalance {
    NSMutableArray *results = [NSMutableArray new];
    for (BMAsset *asset in self.assets.reverseObjectEnumerator) {
        if (asset.realAmount > 0 && ![asset isBeam]) {
            [results addObject:asset];
        }
    }
    return results;
}

-(NSMutableArray<BMAsset*>*_Nonnull)getAssetsWithBalanceWithBeam {
    NSMutableArray *results = [NSMutableArray new];
    BMAsset *beamAsset = nil;
    for (BMAsset *asset in self.assets.reverseObjectEnumerator) {
        if (asset.realAmount > 0 && ![asset isBeam]) {
            [results addObject:asset];
        }
        else if ([asset isBeam]) {
            beamAsset = asset;
        }
    }
    [results insertObject:beamAsset atIndex:0];
    return results;
}

@end

