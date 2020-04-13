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

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:[NSNumber numberWithDouble:self.realValue] forKey: @"realValue"];
    [encoder encodeObject:[NSNumber numberWithInteger:self.value] forKey: @"value"];
    [encoder encodeObject:[NSNumber numberWithInteger:self.type] forKey: @"type"];
}

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if(self)
    {
        self.realValue = [[decoder decodeObjectForKey:@"realValue"] doubleValue];
        self.value = [[decoder decodeObjectForKey:@"realAmount"] integerValue];
        self.type = [[decoder decodeObjectForKey:@"type"] intValue];
    }
    return self;
}

-(NSString*_Nonnull)currencyLongName {
    switch (_type) {
        case BMCurrencyUSD:
            return @"USD (United States Dollar)";
        case BMCurrencyBTC:
            return @"BTC (Bitcoin)";
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
        default:
            return @"";
    }
}

@end
