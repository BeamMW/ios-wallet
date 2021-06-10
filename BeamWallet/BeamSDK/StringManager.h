//
//  StringManager.h
//  BeamWallet
//
//  Created by Denis on 09.06.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMAsset.h"

@interface StringManager : NSObject {
    NSNumberFormatter *formatter;
}

+(StringManager*_Nonnull)sharedManager;

-(NSString*_Nonnull)realAmountString:(double)value;
-(NSString*_Nonnull)realAmountStringAsset:(BMAsset*_Nullable)asset value:(double)value;

@end

