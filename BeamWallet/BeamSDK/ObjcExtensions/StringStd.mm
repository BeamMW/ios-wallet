//
//  String.m
//  BeamTest
//
//  Created by Denis on 2/28/19.
//  Copyright © 2019 Denis. All rights reserved.
//

#import "StringStd.h"

@implementation NSString (Additions)

-(BOOL)isEmpty {
    NSString *trimmed = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmed.length == 0;
}

@end

@implementation NSString (StdExtension)

-(std::string)string {
    return std::string([self UTF8String]);;
}

@end
