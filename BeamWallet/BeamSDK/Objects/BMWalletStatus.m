//
//  BMWalletStatus.m
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

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:[NSNumber numberWithLongLong:_available] forKey: @"available"];
    [encoder encodeObject:[NSNumber numberWithLongLong:_receiving] forKey: @"receiving"];
    [encoder encodeObject:[NSNumber numberWithLongLong:_sending] forKey: @"sending"];
    [encoder encodeObject:[NSNumber numberWithLongLong:_maturing] forKey: @"maturing"];
//    [encoder encodeObject:[NSNumber numberWithLongLong:_linked] forKey: @"linked"];
//    [encoder encodeObject:[NSNumber numberWithLongLong:_unlinked] forKey: @"unlinked"];
    [encoder encodeObject:[NSNumber numberWithLongLong:_shielded] forKey: @"shielded"];

    [encoder encodeObject:[NSNumber numberWithDouble:_realAmount] forKey: @"realAmount"];
    [encoder encodeObject:[NSNumber numberWithDouble:_realReceiving] forKey: @"realReceiving"];
    [encoder encodeObject:[NSNumber numberWithDouble:_realSending] forKey: @"realSending"];
    [encoder encodeObject:[NSNumber numberWithDouble:_realMaturing] forKey: @"realMaturing"];
    [encoder encodeObject:[NSNumber numberWithDouble:_realLinked] forKey: @"realLinked"];
    [encoder encodeObject:[NSNumber numberWithDouble:_realUnlinked] forKey: @"realUnlinked"];
    [encoder encodeObject:[NSNumber numberWithDouble:_realShielded] forKey: @"realShielded"];

    [encoder encodeObject:_currentHeight forKey: @"currentHeight"];
    [encoder encodeObject:_currentStateHash forKey: @"currentStateHash"];
    [encoder encodeObject:_currentStateFullHash forKey: @"currentStateFullHash"];
}

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if(self)
    {
        self.currentHeight = [decoder decodeObjectForKey: @"currentHeight"];
        self.currentStateHash = [decoder decodeObjectForKey: @"currentStateHash"];
        self.currentStateFullHash = [decoder decodeObjectForKey: @"currentStateFullHash"];

        self.available = [[decoder decodeObjectForKey: @"available"] longLongValue];
        self.receiving = [[decoder decodeObjectForKey: @"receiving"] longLongValue];
        self.sending = [[decoder decodeObjectForKey: @"sending"] longLongValue];
        self.maturing = [[decoder decodeObjectForKey: @"maturing"] longLongValue];
//        self.linked = [[decoder decodeObjectForKey: @"linked"] longLongValue];
//        self.unlinked = [[decoder decodeObjectForKey: @"unlinked"] longLongValue];
        self.shielded = [[decoder decodeObjectForKey: @"shielded"] longLongValue];
        
        self.realAmount = [[decoder decodeObjectForKey: @"realAmount"] doubleValue];
        self.realReceiving = [[decoder decodeObjectForKey: @"realReceiving"] doubleValue];
        self.realSending = [[decoder decodeObjectForKey: @"realSending"] doubleValue];
        self.realMaturing = [[decoder decodeObjectForKey: @"realMaturing"] doubleValue];
        self.realLinked = [[decoder decodeObjectForKey: @"realLinked"] doubleValue];
        self.realUnlinked = [[decoder decodeObjectForKey: @"realUnlinked"] doubleValue];
        self.realShielded = [[decoder decodeObjectForKey: @"realShielded"] doubleValue];

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
