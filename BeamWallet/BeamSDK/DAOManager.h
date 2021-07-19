//
//  DAOManager.h
//  BeamWallet
//
//  Created by Denis on 15.07.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DAOManager : NSObject {
}

+(DAOManager*_Nonnull)sharedManager;

-(NSString*_Nonnull)generateAppID:(NSString*_Nonnull)name url:(NSString*_Nonnull)url;

@end
