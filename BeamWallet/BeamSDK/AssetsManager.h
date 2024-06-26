//
// AssetsManager.h
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
#import "BMAsset.h"
#import "BMTransaction.h"

@interface AssetsManager : NSObject {
    NSNumberFormatter *currencyFormatter;
}

+(AssetsManager*_Nonnull)sharedManager;

@property (nonatomic,strong) NSMutableArray<BMAsset*>*_Nonnull assets;

-(NSString*_Nonnull)getAssetColor:(int)value;
-(BMAsset*_Nullable)getAsset:(int)assetId;
-(BMAsset*_Nullable)getAssetByName:(NSString*_Nullable)name;
-(BMTransaction*_Nullable)getLastTransaction:(int)assetId;

-(void)changeAssets;
-(double)getRealAvailableAmount:(int)assetId;

-(NSMutableArray<BMAsset*>*_Nonnull)getAssetsWithBalance;
-(NSMutableArray<BMAsset*>*_Nonnull)getAssetsWithBalanceWithBeam;

@end

