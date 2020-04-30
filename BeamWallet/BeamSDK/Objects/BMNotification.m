//
// BMNotification.m
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

#import "BMNotification.h"
#import "Settings.h"

@implementation BMNotification


-(NSString *_Nonnull)formattedDate {
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:[Settings sharedManager].language];
    
    NSDateFormatter *f = [NSDateFormatter new];
    
    if ([[Settings sharedManager].language isEqualToString:@"zh-Hans"]) {
        if ([[NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]] rangeOfString:@"a"].location!=NSNotFound) {
            [f setDateFormat:@"yyyy MMM dd  |  hh:mm a"];
        }
        else{
            [f setDateFormat:@"yyyy MMM dd  |  HH:mm"];
        }
    }
    else{
        if ([[NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]] rangeOfString:@"a"].location!=NSNotFound) {
            [f setDateFormat:@"dd MMM yyyy  |  hh:mm a"];
        }
        else{
            [f setDateFormat:@"dd MMM yyyy  |  HH:mm"];
        }
    }
    
    [f setLocale:locale];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_createdTime];
    
    return [f stringFromDate:date];
}

@end
