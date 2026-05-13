//
//  BMPublisher.m
//  BeamWallet
//

#import "BMPublisher.h"

@implementation BMPublisher

- (instancetype)init {
    self = [super init];
    if (self) {
        _pubkey = @"";
        _name = @"";
        _aboutMe = @"";
        _website = @"";
        _twitter = @"";
        _linkedin = @"";
        _instagram = @"";
        _telegram = @"";
        _discord = @"";
    }
    return self;
}

@end
