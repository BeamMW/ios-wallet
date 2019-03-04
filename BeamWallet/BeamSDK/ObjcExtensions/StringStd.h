//
//  String.h
//  BeamTest
//
//  Created by Denis on 2/28/19.
//  Copyright © 2019 Denis. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <string>

@interface NSString (Additions)

-(BOOL)isEmpty;

@end


@interface NSString (StdExtension)

-(std::string)string;

@end
