//
// BMAsset.m
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

#import "BMAsset.h"
#import "StringManager.h"
#import "ExchangeManager.h"
#import "BMTransaction.h"
#import "AssetsManager.h"

@implementation BMAsset

+ (BOOL)supportsSecureCoding {
    return NO;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:[NSNumber numberWithLongLong:_available] forKey: @"available"];
    [encoder encodeObject:[NSNumber numberWithLongLong:_receiving] forKey: @"receiving"];
    [encoder encodeObject:[NSNumber numberWithLongLong:_sending] forKey: @"sending"];
    [encoder encodeObject:[NSNumber numberWithLongLong:_assetId] forKey: @"assetId"];
    [encoder encodeObject:[NSNumber numberWithLongLong:_shielded] forKey: @"shielded"];
    [encoder encodeObject:[NSNumber numberWithLongLong:_maturing] forKey: @"maturing"];
    [encoder encodeObject:[NSNumber numberWithLongLong:_maxPrivacy] forKey: @"maxPrivacy"];
    
    [encoder encodeObject:[NSNumber numberWithDouble:_realAmount] forKey: @"realAmount"];
    [encoder encodeObject:[NSNumber numberWithDouble:_realReceiving] forKey: @"realReceiving"];
    [encoder encodeObject:[NSNumber numberWithDouble:_realSending] forKey: @"realSending"];
    [encoder encodeObject:[NSNumber numberWithDouble:_realMaturing] forKey: @"realMaturing"];
    [encoder encodeObject:[NSNumber numberWithDouble:_realShielded] forKey: @"realShielded"];
    [encoder encodeObject:[NSNumber numberWithDouble:_realMaxPrivacy] forKey: @"realMaxPrivacy"];
    
    
    [encoder encodeObject:_unitName forKey: @"unitName"];
    [encoder encodeObject:_nthUnitName forKey: @"nthUnitName"];
    [encoder encodeObject:_shortName forKey: @"shortName"];
    [encoder encodeObject:_shortDesc forKey: @"shortDesc"];
    [encoder encodeObject:_longDesc forKey: @"longDesc"];
    [encoder encodeObject:_name forKey: @"name"];
    [encoder encodeObject:_color forKey: @"color"];
    [encoder encodeObject:_site forKey: @"site"];
    [encoder encodeObject:_paper forKey: @"paper"];
}

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if(self)
    {
        self.unitName = [decoder decodeObjectForKey: @"unitName"];
        self.nthUnitName = [decoder decodeObjectForKey: @"nthUnitName"];
        self.shortName = [decoder decodeObjectForKey: @"shortName"];
        self.shortDesc = [decoder decodeObjectForKey: @"shortDesc"];
        self.longDesc = [decoder decodeObjectForKey: @"longDesc"];
        self.name = [decoder decodeObjectForKey: @"name"];
        self.color = [decoder decodeObjectForKey: @"color"];
        self.site = [decoder decodeObjectForKey: @"site"];
        self.paper = [decoder decodeObjectForKey: @"paper"];

        self.available = [[decoder decodeObjectForKey: @"available"] longLongValue];
        self.receiving = [[decoder decodeObjectForKey: @"receiving"] longLongValue];
        self.sending = [[decoder decodeObjectForKey: @"sending"] longLongValue];
        self.assetId = [[decoder decodeObjectForKey: @"assetId"] longLongValue];
        self.shielded = [[decoder decodeObjectForKey: @"shielded"] longLongValue];
        self.maturing = [[decoder decodeObjectForKey: @"maturing"] longLongValue];
        self.maxPrivacy = [[decoder decodeObjectForKey: @"maxPrivacy"] longLongValue];
        
        self.realAmount = [[decoder decodeObjectForKey: @"realAmount"] doubleValue];
        self.realReceiving = [[decoder decodeObjectForKey: @"realReceiving"] doubleValue];
        self.realSending = [[decoder decodeObjectForKey: @"realSending"] doubleValue];
        self.realMaturing = [[decoder decodeObjectForKey: @"realMaturing"] doubleValue];
        self.realShielded = [[decoder decodeObjectForKey: @"realShielded"] doubleValue];
        self.realMaxPrivacy = [[decoder decodeObjectForKey: @"realMaxPrivacy"] doubleValue];
    }
    return self;
}

-(BOOL)isSendingAndReceiving {
    return (_realSending >0 && _realReceiving > 0);
}

-(BOOL)hasInProgressBalance {
    return (_realSending >0 || _realReceiving > 0);
}

-(UInt64)change {
    if (_realSending > 0 && _realReceiving > 0) {
        return _receiving;
    }
    return  0;
}

-(double)realChange {
    if (_realSending > 0 && _realReceiving > 0) {
        return _realReceiving;
    }
    return  0;
}

-(UInt64)locked {
    return _maturing + _maxPrivacy + [self change];
}

-(double)realLocked {
    return _realMaturing + _realMaxPrivacy + [self realChange];
}

-(BOOL)isBeam {
    return _assetId <= 0;
}

-(BOOL)isBeamX {
    return _assetId == 7;
}

-(double)USD {
    return [[ExchangeManager sharedManager] exchangeValueUSDAsset:self.realAmount assetID:self.assetId];
}

-(UInt64)dateUsed {
    BMTransaction *transaction = [[AssetsManager sharedManager] getLastTransaction:(int)self.assetId];
    if (transaction != nil) {
        return transaction.createdTime;
    }
    return 0;
}

-(BOOL)isIncomming {
    BMTransaction *transaction = [[AssetsManager sharedManager] getLastTransaction:(int)self.assetId];
    if (transaction != nil && transaction.isIncome) {
        return YES;
    }
    return NO;
}

@end
