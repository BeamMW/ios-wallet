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

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.nId forKey: @"nId"];
    [encoder encodeObject:self.pId forKey: @"pId"];
    [encoder encodeObject:self.text forKey: @"text"];

    [encoder encodeObject:[NSNumber numberWithBool:self.isRead] forKey: @"isRead"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isSended] forKey: @"isSended"];

    [encoder encodeObject:[NSNumber numberWithInteger:self.type] forKey: @"type"];

    [encoder encodeObject:[NSNumber numberWithLongLong:self.createdTime] forKey: @"createdTime"];
}

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if(self)
    {
        self.nId = [decoder decodeObjectForKey: @"nId"];
        self.pId = [decoder decodeObjectForKey: @"pId"];
        self.text = [decoder decodeObjectForKey: @"text"];

        self.isRead = [[decoder decodeObjectForKey:@"isRead"] boolValue];
        self.isSended = [[decoder decodeObjectForKey:@"isSended"] boolValue];

        self.type = [[decoder decodeObjectForKey:@"type"] intValue];

        self.createdTime = [[decoder decodeObjectForKey:@"createdTime"] longLongValue];
        
    }
    return self;
}

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
