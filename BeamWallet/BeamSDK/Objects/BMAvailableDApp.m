//
//  BMAvailableDApp.m
//  BeamWallet
//

#import "BMAvailableDApp.h"

@implementation BMAvailableDApp

- (instancetype)init {
    self = [super init];
    if (self) {
        _guid = @"";
        _name = @"";
        _desc = @"";
        _version = @"1.0.0";
        _ipfsCid = @"";
        _publisher = @"";
        _icon = @"";
        _bundledAsset = @"";
        _publisherName = @"";
    }
    return self;
}

@end
