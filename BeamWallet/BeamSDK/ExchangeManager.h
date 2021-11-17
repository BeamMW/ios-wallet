//
// ExchangeManager.h
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
#import "BMCurrency.h"

@interface ExchangeManager : NSObject {
    NSNumberFormatter *currencyFormatter;
}

+(ExchangeManager*_Nonnull)sharedManager;

@property (nonatomic,strong) NSMutableArray<BMCurrency*>*_Nonnull currencies;

-(NSString*_Nonnull)exchangeValueAsset:(double)amount assetID:(UInt64)assetID;
-(NSString*_Nonnull)exchangeValue:(double)amount;
-(NSString*_Nonnull)exchangeValueWithZero:(double)amount;
-(NSString*_Nonnull)exchangeValueFee:(double)amount;
-(NSString*_Nonnull)exchangeValueFrom2:(BMCurrencyType)from to:(BMCurrencyType)to amount:(double)amount;
-(NSString*_Nonnull)exchangeValue:(double)amount to:(BMCurrencyType)to;
-(double)exchangeValueUSDAsset:(double)amount assetID:(UInt64)assetID;
-(NSString*_Nonnull)exchangeValueAssetWithCurrency:(int64_t)value amount:(double)amount assetID:(UInt64)assetID;

-(BOOL)isCurrenciesAvailable;

-(void)changeCurrencies;

@end

