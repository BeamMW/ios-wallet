//
// Settings.h
// BeamWallet
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
#import "BMCurrency.h"
#import "BMMaxPrivacyLock.h"

@class BMLanguage;
@class BMLockScreenValue;
@class BMLogValue;

static double MAX_AMOUNT = 262800000;
static Boolean ENALBE_LANG = false;

typedef enum Target : NSUInteger {
    Testnet = 0,
    Mainnet = 1,
    Masternet = 2,
} Target;


@protocol SettingsModelDelegate <NSObject>
@optional
-(void)onChangeHideAmounts;
-(void)onChangeLanguage;
-(void)onChangeDarkMode;
@end

@interface Settings : NSObject {
    int randomId;
}

+(Settings*_Nonnull)sharedManager;

// delegates
@property (nonatomic,readonly) NSHashTable * _Nonnull delegates;

-(void)addDelegate:(id<SettingsModelDelegate>_Nullable) delegate;
-(void)removeDelegate:(id<SettingsModelDelegate>_Nullable) delegate;

@property (nonatomic, assign) Target target;

@property (nonatomic, assign) BOOL isLocalNode;
@property (nonatomic, assign) BOOL isNeedaskPasswordForSend;
@property (nonatomic, assign) BOOL isEnableBiometric;
@property (nonatomic, assign) BOOL isHideAmounts;
@property (nonatomic, assign) BOOL isAskForHideAmounts;
@property (nonatomic, assign) int lockScreenSeconds;
@property (nonatomic, assign) int lockMaxPrivacyValue;
@property (nonatomic, assign) BOOL isAllowOpenLink;
@property (nonatomic, assign) BOOL connectToRandomNode;
@property (nonatomic, assign) int logDays;
@property (nonatomic, assign) BOOL isDarkMode;
@property (nonatomic, assign) BMCurrencyType currency;
@property (nonatomic, assign) BOOL isNotificationWalletON;
@property (nonatomic, assign) BOOL isNotificationNewsON;
@property (nonatomic, assign) BOOL isNotificationTransactionON;
@property (nonatomic, assign) BOOL isNotificationAddressON;

@property (nonatomic, strong) NSString * _Nonnull explorerAddress;
@property (nonatomic, strong) NSString * _Nonnull nodeAddress;
@property (nonatomic, strong) NSString * _Nonnull whereBuyAddress;
@property (nonatomic, strong) NSString * _Nonnull language;
@property (nonatomic, strong) NSString * _Nonnull documentationAddress;

@property (nonatomic, assign) int maxAddressDurationHours;
@property (nonatomic, assign) int maxAddressDurationSeconds;

@property (nonatomic, assign) int maxTokens;

@property (nonatomic, assign) BOOL isNodeProtocolEnabled;

@property (nonatomic, assign) int minConfirmations;

-(void)setDefaultDarkMode:(BOOL)isSystemMode;

-(BOOL)isChangedNode;
-(void)resetSettings;
-(void)resetNode;
-(void)removeCustomNode;
-(void)resetDataBase;

-(NSString*_Nonnull)walletStoragePath;
-(NSString*_Nonnull)logPath;

-(int)nodePort;
-(NSString*_Nonnull)localNodeStorage;
-(NSString*_Nonnull)localNodeTemdDir;

-(NSString*_Nonnull)languageName;
-(NSArray <BMLanguage*> * _Nonnull)languages;
-(NSString*_Nonnull)shortLanguageName;

-(NSString*_Nonnull)customNode;

-(NSArray <BMLockScreenValue*> * _Nonnull)lockScreenValues;
-(BMLockScreenValue*_Nonnull)currentLocedValue;

-(NSArray <BMLogValue*> * _Nonnull)logValues;
-(BMLogValue*_Nonnull)currentLogValue;

-(NSString*_Nonnull)currencyName;

-(NSArray <BMMaxPrivacyLock*> * _Nonnull)maxPrivacyLockValues;
-(BMMaxPrivacyLock*_Nonnull)currentMaxPrivacyLockValue;

-(NSString*_Nonnull)dAppUrl;
-(NSString*_Nonnull)assetBlockchainUrl:(int)assetId;


@end
