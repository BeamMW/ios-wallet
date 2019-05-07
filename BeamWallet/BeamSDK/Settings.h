//
// Settings.h
// BeamTest
//
// Copyright 2018 Beam Development
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

static double MAX_AMOUNT = 262800000;

typedef enum Target : NSUInteger {
    Testnet = 0,
    Mainnet = 1,
    Masternet = 2,
} Target;


@protocol SettingsModelDelegate <NSObject>
@optional
-(void)onChangeHideAmounts;
@end

@interface Settings : NSObject

+(Settings*_Nonnull)sharedManager;

// delegates
@property (nonatomic,strong) NSHashTable * _Nonnull delegates;

-(void)addDelegate:(id<SettingsModelDelegate>_Nullable) delegate;
-(void)removeDelegate:(id<SettingsModelDelegate>_Nullable) delegate;

@property (nonatomic, assign) Target target;

@property (nonatomic, assign) BOOL isLocalNode;
@property (nonatomic, assign) BOOL isNeedaskPasswordForSend;
@property (nonatomic, assign) BOOL isEnableBiometric;
@property (nonatomic, assign) BOOL isHideAmounts;
@property (nonatomic, assign) BOOL isAskForHideAmounts;
@property (nonatomic, assign) int lockScreenSeconds;
@property (nonatomic, assign) BOOL isAllowOpenLink;

@property (nonatomic, strong) NSString * _Nonnull explorerAddress;

@property (nonatomic, strong) NSString * _Nonnull nodeAddress;
-(BOOL)isChangedNode;

-(NSString*_Nonnull)walletStoragePath;

-(NSString*_Nonnull)logPath;

-(int)nodePort;
-(NSString*_Nonnull)localNodeStorage;
-(NSString*_Nonnull)localNodeTemdDir;
-(NSArray*_Nonnull)localNodePeers;

@end
