//
//  BMApp.m
//  BeamWallet
//
//  Created by Denis on 01.09.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

#import "BMApp.h"

@implementation BMApp

-(void)setAPIResult:(NSDictionary*)dct {
    _name = [dct valueForKey:@"name"];
    _desc = [dct valueForKey:@"description"];
    _url = [dct valueForKey:@"url"];
    _icon = [dct valueForKey:@"icon"];
    
    if ([dct valueForKey:@"min_api_version"]) {
        _min_api_version = [[dct valueForKey:@"min_api_version"] stringValue];
    }
    else {
        _min_api_version = @"";
    }
    
    if ([dct valueForKey:@"api_version"]) {
        _api_version = [[dct valueForKey:@"api_version"] stringValue];
    }
    else {
        _api_version = @"current";
    }
}

@end
