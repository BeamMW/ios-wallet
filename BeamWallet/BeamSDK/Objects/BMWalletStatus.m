//
//  BMWalletStatus.m
//  BeamWallet
//
// Copyright 2026 Beam Development
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

#import "BMWalletStatus.h"

@implementation BMWalletStatus

-(id)init{
    self = [super init];
    
    _available = 0;
    _sending = 0;
    _receiving = 0;
    _maturing = 0;
    _realAmount = 0;
    _realReceiving = 0;
    _realMaturing = 0;
    _realSending = 0;

    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

+(NSArray<Class>*)allowedTopLevelClasses {
    return @[NSArray.class, NSString.class, NSNumber.class];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:[NSNumber numberWithLongLong:_available] forKey: @"available"];
    [encoder encodeObject:[NSNumber numberWithLongLong:_receiving] forKey: @"receiving"];
    [encoder encodeObject:[NSNumber numberWithLongLong:_sending] forKey: @"sending"];
    [encoder encodeObject:[NSNumber numberWithLongLong:_maturing] forKey: @"maturing"];
    [encoder encodeObject:[NSNumber numberWithLongLong:_shielded] forKey: @"shielded"];
    [encoder encodeObject:[NSNumber numberWithLongLong:_maxPrivacy] forKey: @"maxPrivacy"];

    [encoder encodeObject:[NSNumber numberWithDouble:_realAmount] forKey: @"realAmount"];
    [encoder encodeObject:[NSNumber numberWithDouble:_realReceiving] forKey: @"realReceiving"];
    [encoder encodeObject:[NSNumber numberWithDouble:_realSending] forKey: @"realSending"];
    [encoder encodeObject:[NSNumber numberWithDouble:_realMaturing] forKey: @"realMaturing"];
    [encoder encodeObject:[NSNumber numberWithDouble:_realShielded] forKey: @"realShielded"];
    [encoder encodeObject:[NSNumber numberWithDouble:_realMaxPrivacy] forKey: @"realMaxPrivacy"];

    [encoder encodeObject:_currentHeight forKey: @"currentHeight"];
    [encoder encodeObject:_currentStateHash forKey: @"currentStateHash"];
    [encoder encodeObject:_currentStateFullHash forKey: @"currentStateFullHash"];
}

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if(self)
    {
        self.currentHeight = [decoder decodeObjectOfClass:[NSString class] forKey: @"currentHeight"];
        self.currentStateHash = [decoder decodeObjectOfClass:[NSString class] forKey: @"currentStateHash"];
        self.currentStateFullHash = [decoder decodeObjectOfClass:[NSString class] forKey: @"currentStateFullHash"];

        self.available = [[decoder decodeObjectOfClass:[NSNumber class] forKey: @"available"] longLongValue];
        self.receiving = [[decoder decodeObjectOfClass:[NSNumber class] forKey: @"receiving"] longLongValue];
        self.sending = [[decoder decodeObjectOfClass:[NSNumber class] forKey: @"sending"] longLongValue];
        self.maturing = [[decoder decodeObjectOfClass:[NSNumber class] forKey: @"maturing"] longLongValue];
        self.shielded = [[decoder decodeObjectOfClass:[NSNumber class] forKey: @"shielded"] longLongValue];
        self.maxPrivacy = [[decoder decodeObjectOfClass:[NSNumber class] forKey: @"maxPrivacy"] longValue];

        self.realAmount = [[decoder decodeObjectOfClass:[NSNumber class] forKey: @"realAmount"] doubleValue];
        self.realReceiving = [[decoder decodeObjectOfClass:[NSNumber class] forKey: @"realReceiving"] doubleValue];
        self.realSending = [[decoder decodeObjectOfClass:[NSNumber class] forKey: @"realSending"] doubleValue];
        self.realMaturing = [[decoder decodeObjectOfClass:[NSNumber class] forKey: @"realMaturing"] doubleValue];
        self.realShielded = [[decoder decodeObjectOfClass:[NSNumber class] forKey: @"realShielded"] doubleValue];
        self.realMaxPrivacy = [[decoder decodeObjectOfClass:[NSNumber class] forKey: @"realMaxPrivacy"] doubleValue];
    }
    return self;
}

-(BOOL)isSendingAndReceiving {
    return (_realSending >0 && _realReceiving > 0);
}
    
-(BOOL)hasInProgressBalance {
    return (_realSending >0 || _realReceiving > 0);
}

@end
