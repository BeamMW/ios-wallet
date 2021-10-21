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

static NSString *assetsKey = @"assetsKeyNew_2";

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
    
    if (_assets == nil) {
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
        beamX.assetId = 31;
        beamX.nthUnitName = @"BEAMX";
        beamX.unitName = @"BEAMX";
        beamX.color = @"#977dff";
        beamX.shortName = @"BEAMX";
        beamX.shortDesc = @"";
        beamX.longDesc = @"";
        beamX.site = @"";
        beamX.paper = @"";
        [_assets addObject:beamX];
    }
    
    return self;
}

-(NSString*_Nonnull)getAssetColor:(int)value {
    if (value == 31) {
        return  @"#977dff";
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
    
    if (assetId==31) {
        
    }
    
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
    NSMutableArray *notif = [NSMutableArray arrayWithArray:self->_assets];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:notif requiringSecureCoding:YES error:&error];
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:assetsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    });
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

