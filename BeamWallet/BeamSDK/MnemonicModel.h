//
//  MnemonicModel.h
//  BeamTest
//
//  Created by Denis on 2/28/19.
//  Copyright © 2019 Denis. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MnemonicModel : NSObject

+(NSString*)generatePhrase;
+(BOOL)isValidPhrase:(NSString*)phrase;
+(BOOL)isValidWord:(NSString*)word;

@end
