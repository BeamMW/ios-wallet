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
}

@end
