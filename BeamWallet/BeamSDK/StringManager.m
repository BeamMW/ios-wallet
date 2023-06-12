//
//  StringManager.m
//  BeamWallet
//
//  Created by Denis on 09.06.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

#import "StringManager.h"
#import "Settings.h"

@implementation StringManager

+ (StringManager*_Nonnull)sharedManager {
    static StringManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

-(id)init{
    self = [super init];

    formatter = [NSNumberFormatter new];
    formatter.currencyCode = @"";
    formatter.currencySymbol = @"";
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 10;
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    formatter.numberStyle = NSNumberFormatterCurrencyAccountingStyle;
    
    return self;
}

-(NSString*_Nonnull)realAmountString:(double)value{
    NSString *number = [formatter stringFromNumber:[NSNumber numberWithDouble:value]];
    return number;
}

-(NSString*_Nonnull)realAmountStringAsset:(BMAsset*_Nullable)asset value:(double)value {
    if ([[Settings sharedManager] isHideAmounts]) {
        if(asset.isBeam) {
            return @"BEAM";
        }
        else {
            return asset.unitName;
        }
    }
    else {
        NSString *number = [formatter stringFromNumber:[NSNumber numberWithDouble:value]];
        if(asset.isBeam) {
            return [[[NSString stringWithFormat:@"%@ %@", number, @"BEAM"] stringByReplacingOccurrencesOfString:@"(" withString:@""] stringByReplacingOccurrencesOfString:@")" withString:@""];
        }
        else {
            return [[[NSString stringWithFormat:@"%@ %@", number, asset.unitName] stringByReplacingOccurrencesOfString:@"(" withString:@""] stringByReplacingOccurrencesOfString:@")" withString:@""];
        }
    }
}

@end
