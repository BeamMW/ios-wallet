//
//  BMAddress.m
//  BeamWallet
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

#import "BMAddress.h"
#import "BMCategory.h"
#import "Settings.h"
#import "StringLocalize.h"
#import "AppModel.h"
#import "Color.h"
#include "wallet/client/wallet_client.h"

@implementation BMAddress


+(BMAddress*_Nonnull)emptyAddress{
    BMAddress *empty = [BMAddress new];
    empty.categories = [NSMutableArray new];
    empty.label = @"";
    return empty;
}

+(BMAddress*_Nonnull)fromAddress:(BMAddress*_Nonnull)address{
    BMAddress *copied = [BMAddress new];
    copied.walletId = [NSString stringWithString:address.walletId];
    copied.categories = [NSMutableArray arrayWithArray:address.categories];
    copied.label = [NSString stringWithString:address.label];
    copied.duration = address.duration;
    copied.createTime = address.createTime;
    return copied;
}

-(BOOL)isExpired {
    if (_duration == 0)
    {
        return NO;
    }
    return beam::getTimestamp() > [self getExpirationTime];
}

-(UInt64)getExpirationTime
{
    if (_duration == 0)
    {
        return 0;
    }
    return _createTime + _duration;
}

-(NSString*_Nonnull)expiredFormattedDate{
    NSDateFormatter *f = [self shortFormatter];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970: [self getExpirationTime]];
    
    return [f stringFromDate:date];
}

-(NSString*_Nonnull)formattedDate {
    if (_duration == 0)
    {
        return @"never";
    }

    NSDateFormatter *f = [self formatter];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970: [self getExpirationTime]];
    
    return [f stringFromDate:date];
}

-(NSString*_Nonnull)agoDate {
    if (_duration == 0)
    {
        return @"never";
    }
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970: [self getExpirationTime]];

    int totalSeconds = date.timeIntervalSince1970 - [NSDate date].timeIntervalSince1970;
    int m = (totalSeconds / 60) % 60;
    int h = totalSeconds / 3600;
    
    if(h == (Settings.sharedManager.maxAddressDurationHours - 1) && m > 55) {
        return [NSString stringWithFormat:@"%d %@", Settings.sharedManager.maxAddressDurationHours , [@"h" localized]];
    }
    else if (m <= 1 && h > 0) {
        return [NSString stringWithFormat:@"%d %@", h, [@"h" localized]];
    }
    else if (h == 0) {
        return [NSString stringWithFormat:@"%d %@", m, [@"m" localized]];
    }
    else{
       return [NSString stringWithFormat:@"%d %@ %d %@", h, [@"h" localized], m, [@"m" localized]];
    }
}

-(NSString*_Nonnull)nowDate {
    NSDateFormatter *f = [self formatter];

    NSDate *date = [NSDate date];
    
    return [f stringFromDate:date];
}

-(NSString*)expireNowDate {
    if (_isNowActiveDuration == 0)
    {
        return @"never";
    }
    
    NSDateFormatter *f = [self formatter];
    
    NSDate *date = [[NSDate date] dateByAddingTimeInterval:_isNowActiveDuration];
    
    return [f stringFromDate:date];
}

-(int)isNowActiveDurationInHours {
    if (_isNowActiveDuration == 0) {
        return 0;
    }
    
    return (((int)_isNowActiveDuration/60)/60);
}

-(int)durationInHours {
    if (_duration == 0) {
        return 0;
    }
    
    return (((int)_duration/60)/60);
}

- (NSDateFormatter *)formatter
{
    if (!_formatter)
    {
        _formatter = [[NSDateFormatter alloc] init];
       
        if ([[Settings sharedManager].language isEqualToString:@"zh-Hans"]) {
            if ([[NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]] rangeOfString:@"a"].location!=NSNotFound) {
                [_formatter setDateFormat:@"yyyy MMM dd  |  hh:mm a"];
            }
            else{
                [_formatter setDateFormat:@"yyyy MMM dd  |  HH:mm"];
            }
        }
        else{
            if ([[NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]] rangeOfString:@"a"].location!=NSNotFound) {
                [_formatter setDateFormat:@"dd MMM yyyy  |  hh:mm a"];
            }
            else{
                [_formatter setDateFormat:@"dd MMM yyyy  |  HH:mm"];
            }
        }
    }
    

    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:[Settings sharedManager].language];
    [_formatter setLocale:locale];
    
    return _formatter;
}

- (NSDateFormatter *)shortFormatter
{
    if (!_shortFormatter)
    {
        _shortFormatter = [[NSDateFormatter alloc] init];
        
        if ([[Settings sharedManager].language isEqualToString:@"zh-Hans"]) {
            [_shortFormatter setDateFormat:@"yyyy MMM dd"];
        }
        else{
            [_shortFormatter setDateFormat:@"dd MMM yyyy"];
        }
    }
    
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:[Settings sharedManager].language];
    [_shortFormatter setLocale:locale];
    
    return _shortFormatter;
}

-(NSMutableAttributedString*_Nonnull)categoriesName {
    NSMutableArray <BMCategory*> * result = [NSMutableArray array];
    
    for (NSString *s in _categories) {
        BMCategory *c = [[AppModel sharedManager] findCategoryById:s];
        if (c!=nil) {
            [result addObject:c];
        }
    }
        
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:@""];
    
    if(result.count > 0) {
        for (BMCategory *category in result) {
            NSMutableAttributedString *categoryString = [[NSMutableAttributedString alloc] initWithString:category.name];
            [categoryString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:category.color] range:NSMakeRange(0, category.name.length)];
            [attrString appendAttributedString:categoryString];
            if (result.count > 1 && ![category.name isEqualToString:result.lastObject.name])
            {
                NSMutableAttributedString *coma = [[NSMutableAttributedString alloc] initWithString:@", "];
                [coma addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#8DA1AD"] range:NSMakeRange(0, 1)];

                [attrString appendAttributedString:coma];
            }
        }
    }

    return attrString;
}

@end
