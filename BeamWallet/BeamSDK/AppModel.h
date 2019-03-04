//
//  AppModel.h
//  BeamTest
//
//  Created by Denis on 2/28/19.
//  Copyright © 2019 Denis. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WalletModelDelegate <NSObject>
@optional
-(void)onSyncProgressUpdated:(int)done total:(int)total;
-(void)onWalletError:(NSString*)error;
@end

@interface AppModel : NSObject

-(BOOL)isWalletAlreadyAdded;
-(BOOL)createWallet:(NSString*)phrase pass:(NSString*)pass;
-(BOOL)openWallet:(NSString*)pass;
-(BOOL)canOpenWallet:(NSString*)pass;
-(void)resetWallet;

+(AppModel*)sharedManager;

@property (nonatomic,weak) id <WalletModelDelegate> walletDelegate;

@end
