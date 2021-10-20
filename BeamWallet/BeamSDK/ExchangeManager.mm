//
// ExchangeManager.m
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

#import "ExchangeManager.h"
#import "Settings.h"
#include "wallet/core/wallet.h"

static NSString *currenciesKey = @"currenciesKey";

@implementation ExchangeManager

+ (ExchangeManager*_Nonnull)sharedManager {
    static ExchangeManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

-(id)init{
    self = [super init];
    
    NSData *dataNotifications = [[NSUserDefaults standardUserDefaults] objectForKey:currenciesKey];
    if(dataNotifications != nil) {
        NSError *error;
        NSSet *classes = [NSSet setWithObjects:[NSArray class], [BMCurrency class], nil];
        _currencies = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:dataNotifications error:&error];
        NSLog(@"%@",error);
    }
    
    if (_currencies == nil) {
        _currencies = [[NSMutableArray alloc] init];
    }
    
    currencyFormatter = [[NSNumberFormatter alloc] init];
    currencyFormatter.currencyCode = @"";
    currencyFormatter.currencySymbol = @"";
    currencyFormatter.minimumFractionDigits = 0;
    currencyFormatter.maximumFractionDigits = 10;
    currencyFormatter.numberStyle = NSNumberFormatterCurrencyAccountingStyle;
    currencyFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    
    return self;
}

-(NSString*_Nonnull)exchangeValue:(double)amount to:(BMCurrencyType)to {
    for (BMCurrency *currency in [_currencies objectEnumerator].allObjects) {
        if(currency.type == to && currency.value > 0) {
            currencyFormatter.maximumFractionDigits = currency.maximumFractionDigits;
            currencyFormatter.positiveSuffix = [NSString stringWithFormat:@" %@",currency.code];
            currencyFormatter.negativeSuffix = [NSString stringWithFormat:@" %@",currency.code];
            
            double value = double(int64_t(currency.value)) / beam::Rules::Coin;
            double rate = value * amount;
            return [currencyFormatter stringFromNumber:[NSNumber numberWithDouble:rate]];
        }
    }
    
    return @"";
}

-(NSString*_Nonnull)exchangeValueAssetWithCurrency:(int64_t)value amount:(double)amount assetID:(UInt64)assetID {
    
    if(amount == 0.0 || [Settings sharedManager].isHideAmounts) {
        return @"";
    }
    
    BMCurrencyType currency = Settings.sharedManager.currency;
    
    if (currency == BMCurrencyUSD) {
        currencyFormatter.maximumFractionDigits = 2;
        currencyFormatter.positiveSuffix = [NSString stringWithFormat:@" %@", @"USD"];
        currencyFormatter.negativeSuffix = [NSString stringWithFormat:@" %@", @"USD"];
    }
    else if(currency == BMCurrencyETH) {
        currencyFormatter.maximumFractionDigits = 10;
        currencyFormatter.positiveSuffix = [NSString stringWithFormat:@" %@", @"ETH"];
        currencyFormatter.negativeSuffix = [NSString stringWithFormat:@" %@", @"ETH"];
    }
    else {
        currencyFormatter.positiveSuffix = [NSString stringWithFormat:@" %@", @"BTC"];
        currencyFormatter.negativeSuffix = [NSString stringWithFormat:@" %@", @"BTC"];
        currencyFormatter.maximumFractionDigits = 10;
    }
    

    
    double valueResult = double(int64_t(value)) / beam::Rules::Coin;
    double rate = valueResult * amount;
    return [currencyFormatter stringFromNumber:[NSNumber numberWithDouble:rate]];
}

-(NSString*_Nonnull)exchangeValueAsset:(double)amount assetID:(UInt64)assetID {
    if(amount == 0.0 || [Settings sharedManager].isHideAmounts) {
        return @"";
    }
    
    NSArray *currencies = [NSArray arrayWithArray:[_currencies objectEnumerator].allObjects];
    for (BMCurrency *currency in currencies) {
        if(currency.type == Settings.sharedManager.currency && currency.value > 0 && currency.assetId == assetID) {
            currencyFormatter.maximumFractionDigits = currency.maximumFractionDigits;
            currencyFormatter.positiveSuffix = [NSString stringWithFormat:@" %@",currency.code];
            currencyFormatter.negativeSuffix = [NSString stringWithFormat:@" %@",currency.code];
            
            double value = double(int64_t(currency.value)) / beam::Rules::Coin;
            double rate = value * amount;
            return [currencyFormatter stringFromNumber:[NSNumber numberWithDouble:rate]];
        }
    }
    
    return @"";
}

-(double)exchangeValueUSDAsset:(double)amount assetID:(UInt64)assetID {
    if(amount == 0.0 || [Settings sharedManager].isHideAmounts) {
        return 0.0;
    }
    
    NSArray *currencies = [NSArray arrayWithArray:[_currencies objectEnumerator].allObjects];
    for (BMCurrency *currency in currencies) {
        if(currency.type == BMCurrencyUSD && currency.value > 0 && currency.assetId == assetID) {
            currencyFormatter.maximumFractionDigits = currency.maximumFractionDigits;
            currencyFormatter.positiveSuffix = [NSString stringWithFormat:@" %@",currency.code];
            currencyFormatter.negativeSuffix = [NSString stringWithFormat:@" %@",currency.code];
            
            double value = double(int64_t(currency.value)) / beam::Rules::Coin;
            double rate = value * amount;
            return rate;
        }
    }
    
    return 0.0;
}

-(NSString*_Nonnull)exchangeValue:(double)amount {
    if(amount == 0.0) {
        return [NSString stringWithFormat:@"-%@",Settings.sharedManager.currencyName];
    }
    
    NSArray *currencies = [NSArray arrayWithArray:[_currencies objectEnumerator].allObjects];
    for (BMCurrency *currency in currencies) {
        if(currency.type == Settings.sharedManager.currency && currency.value > 0) {
            currencyFormatter.maximumFractionDigits = currency.maximumFractionDigits;
            currencyFormatter.positiveSuffix = [NSString stringWithFormat:@" %@",currency.code];
            currencyFormatter.negativeSuffix = [NSString stringWithFormat:@" %@",currency.code];
            
            double value = double(int64_t(currency.value)) / beam::Rules::Coin;
            double rate = value * amount;
            return [currencyFormatter stringFromNumber:[NSNumber numberWithDouble:rate]];
        }
    }
    
    return [NSString stringWithFormat:@"-%@",Settings.sharedManager.currencyName];
}

-(NSString*_Nonnull)exchangeValueWithZero:(double)amount {
    NSString *result = [self exchangeValue:amount];
    return [result stringByReplacingOccurrencesOfString:@"-" withString:@"0 "];
}

-(NSString*_Nonnull)exchangeValueFrom2:(BMCurrencyType)from to:(BMCurrencyType)to amount:(double)amount {
    if(amount == 0) {
        return @"";
    }
    
    if(from == BEAM) {
        for (BMCurrency *currency in _currencies) {
            if(currency.type == Settings.sharedManager.currency && currency.value > 0) {
                currencyFormatter.maximumFractionDigits = currency.maximumFractionDigits;
                currencyFormatter.positiveSuffix = [NSString stringWithFormat:@" %@",currency.code];
                
                double value = double(int64_t(currency.value)) / beam::Rules::Coin;
                double rate = value * (amount / beam::Rules::Coin);
                if(rate < 0.01 && currency.type == BMCurrencyUSD) {
                    return @"< 1 cent";
                }
                NSString *result = [currencyFormatter stringFromNumber:[NSNumber numberWithDouble:rate]];
                if([result isEqualToString:@"0 BTC"]) {
                    rate = rate * 100000000;
                    currencyFormatter.positiveSuffix = [NSString stringWithFormat:@" %@",@"satoshis"];
                    result = [currencyFormatter stringFromNumber:[NSNumber numberWithDouble:rate]];
                }
                return result;
            }
        }
        
        return [NSString stringWithFormat:@"-%@",Settings.sharedManager.currencyName];
    }
    else  {
        for (BMCurrency *currency in _currencies) {
            if(currency.type == from && currency.value > 0) {
                
                NSNumberFormatter *formatter = [NSNumberFormatter new];
                formatter.currencyCode = @"";
                formatter.currencySymbol = @"";
                formatter.minimumFractionDigits = 0;
                formatter.maximumFractionDigits = 2;
                formatter.numberStyle = NSNumberFormatterCurrencyStyle;
                formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
                
                double value = double(int64_t(currency.value)) / beam::Rules::Coin;
                double rate = (amount) / value;
                NSString *result = [NSString stringWithFormat:@"%@ BEAM",[formatter stringFromNumber:[NSNumber numberWithDouble:rate]]];
                return result;
            }
        }
        
        return [NSString stringWithFormat:@"-%@",Settings.sharedManager.currencyName];
    }
}

-(NSString*_Nonnull)exchangeValueFee:(double)amount {
    if(amount == 0) {
        return @"";
    }
    for (BMCurrency *currency in _currencies) {
        if(currency.type == Settings.sharedManager.currency && currency.value > 0) {
            currencyFormatter.maximumFractionDigits = currency.maximumFractionDigits;
            currencyFormatter.positiveSuffix = [NSString stringWithFormat:@" %@",currency.code];
            
            double value = double(int64_t(currency.value)) / beam::Rules::Coin;
            double rate = value * (amount / beam::Rules::Coin);
            if(rate < 0.01 && currency.type == BMCurrencyUSD) {
                return @"< 1 cent";
            }
            NSString *result = [currencyFormatter stringFromNumber:[NSNumber numberWithDouble:rate]];
            if([result isEqualToString:@"0 BTC"]) {
                rate = rate * 100000000;
                currencyFormatter.positiveSuffix = [NSString stringWithFormat:@" %@",@"satoshis"];
                result = [currencyFormatter stringFromNumber:[NSNumber numberWithDouble:rate]];
            }
            return result;
        }
    }
    
    return [NSString stringWithFormat:@"-%@",Settings.sharedManager.currencyName];
}

-(BOOL)isCurrenciesAvailable {
    return _currencies.count > 0;
}

-(void)changeCurrencies {
    NSMutableArray *tr = [NSMutableArray arrayWithArray:self->_currencies];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:tr requiringSecureCoding:YES error:&error];
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:currenciesKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    });
}

@end

