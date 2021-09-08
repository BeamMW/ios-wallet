//
//  DAOManager.h
//  BeamWallet
//
//  Created by Denis on 01.09.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMApp.h"
#import "WalletModel.h"

@interface DAOManager : NSObject {
    
}

-(id _Nonnull)initWithWallet:(WalletModel::Ptr)wallet;

-(BOOL)appSupported:(BMApp*_Nonnull)app;
-(void)launchApp:(BMApp*_Nonnull)app;
-(void)callWalletApi:(NSString*_Nonnull)json;
-(void)contractInfoApproved:(NSString*_Nonnull)json;
-(void)contractInfoRejected:(NSString*_Nonnull)json;



@end

