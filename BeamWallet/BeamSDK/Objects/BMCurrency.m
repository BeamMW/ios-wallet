//
// BMCurrency.m
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
#import "BMCurrency.h"

@implementation BMCurrency

+ (BOOL)supportsSecureCoding {
    return NO;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:[NSNumber numberWithDouble:self.realValue] forKey: @"realValue"];
    [encoder encodeObject:[NSNumber numberWithLongLong:self.value] forKey: @"value"];
    [encoder encodeObject:[NSNumber numberWithInteger:self.type] forKey: @"type"];
    [encoder encodeObject:[NSNumber numberWithInteger:self.maximumFractionDigits] forKey: @"maximumFractionDigits"];
    [encoder encodeObject:self.code forKey: @"code"];
    [encoder encodeObject:self.name forKey: @"name"];
    [encoder encodeObject:[NSNumber numberWithInteger:self.assetId] forKey: @"assetId"];
}

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if(self)
    {
        self.realValue = [[decoder decodeObjectForKey:@"realValue"] doubleValue];
        self.value = [[decoder decodeObjectForKey:@"value"] longLongValue];
        self.type = [[decoder decodeObjectForKey:@"type"] intValue];
        self.maximumFractionDigits = [[decoder decodeObjectForKey:@"maximumFractionDigits"] intValue];
        self.code = [decoder decodeObjectForKey:@"code"];
        self.name = [decoder decodeObjectForKey:@"name"];
        self.assetId = [[decoder decodeObjectForKey:@"assetId"] intValue];
    }
    return self;
}

-(NSString*_Nonnull)currencyLongName {
    switch (_type) {
        case BMCurrencyUSD:
            return @"USD (United States Dollar)";
        case BMCurrencyBTC:
            return @"BTC (Bitcoin)";
        case BMCurrencyETH:
            return @"ETH (Ethereum)";
        case BEAM:
            return @"BEAM";
        default:
            return @"";
    }
}

-(NSString*_Nonnull)currencyName {
    switch (_type) {
        case BMCurrencyUSD:
            return @"USD";
        case BMCurrencyBTC:
            return @"BTC";
        case BMCurrencyETH:
            return @"ETH";
        default:
            return @"";
    }
}

@end
