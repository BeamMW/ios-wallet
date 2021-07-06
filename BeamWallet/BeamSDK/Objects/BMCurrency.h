//
// BMCurrency.h
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

enum {
    BEAM = 0,
    BMCurrencyUSD = 1,
    BMCurrencyBTC = 2,
    BMCurrencyETH = 4
};
typedef int BMCurrencyType;

@interface BMCurrency : NSObject <NSSecureCoding> 

@property (nonatomic,assign) UInt64 value;
@property (nonatomic,assign) double realValue;
@property (nonatomic,assign) int maximumFractionDigits;
@property (nonatomic,assign) BMCurrencyType type;
@property (nonatomic,strong) NSString* _Nonnull code;
@property (nonatomic,strong) NSString* _Nullable name;
@property (nonatomic,assign) int assetId;

-(NSString*_Nonnull)currencyName;
-(NSString*_Nonnull)currencyLongName;

@end
