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
#import "Settings.h"
#import "StringLocalize.h"
#include "wallet/wallet_client.h"

@implementation BMAddress


+(BMAddress*)emptyAddress{
    BMAddress *empty = [BMAddress new];
    empty.category = @"";
    empty.label = @"";
    return empty;
}

+(BMAddress*)fromAddress:(BMAddress*)address{
    BMAddress *copied = [BMAddress new];
    copied.walletId = [NSString stringWithString:address.walletId];
    copied.category = [NSString stringWithString:address.category];
    copied.label = [NSString stringWithString:address.label];
    copied.duration = address.duration;
    copied.createTime = address.createTime;
    return copied;
}

-(NSString*)categoryName{
    if (_categoryName == nil){
        return @"";
    }
    return _categoryName;
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

-(NSString*)formattedDate {
    if (_duration == 0)
    {
        return @"never";
    }

    NSDateFormatter *f = [self formatter];

    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970: [self getExpirationTime]];
    
    return [f stringFromDate:date];
}

-(NSString*)agoDate {
    if (_duration == 0)
    {
        return @"never";
    }
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970: [self getExpirationTime]];

    int totalSeconds = date.timeIntervalSince1970 - [NSDate date].timeIntervalSince1970;
    int m = (totalSeconds / 60) % 60;
    int h = totalSeconds / 3600;
    
    if(h == 23 && m > 55) {
        return [NSString stringWithFormat:@"%d %@", 24, [@"h" localized]];
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

-(NSString*)nowDate {
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
        [_formatter setDateFormat:@"dd MMM yyyy  |  HH:mm"];
    }
    
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:[Settings sharedManager].language];
    [_formatter setLocale:locale];
    
    return _formatter;
}

@end
