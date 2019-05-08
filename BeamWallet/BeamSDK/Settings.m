//
// Settings.m
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

#import "Settings.h"
#import "AppModel.h"

@implementation Settings

static NSString *askKey = @"isNeedaskPasswordForSend";
static NSString *lockScreen = @"lockScreen";
static NSString *biometricKey = @"biometricKey";
static NSString *hideAmountsKey = @"isHideAmounts";
static NSString *nodeKey = @"nodeKey";
static NSString *askHideAmountsKey = @"askHideAmountsKey";
static NSString *alowOpenLinkKey = @"alowOpenLinkKey";

+ (Settings*_Nonnull)sharedManager {
    static Settings *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

-(id)init {
    self = [super init];
    
    _delegates = [[NSHashTable alloc] init];

    NSString *target =  [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"];
    
    if ([target isEqualToString:@"BeamWalletTestNet"] || [target isEqualToString:@"BeamWalletNotificationViewTestNet"]) {
        _target = Testnet;
    }
    else if ([target isEqualToString:@"BeamWalletMasterNet"] || [target isEqualToString:@"BeamWalletNotificationViewMasterNet"]) {
        _target = Masternet;
    }
    else{
        _target = Mainnet;
    }
    
    _isLocalNode = NO;
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:askKey]) {
        _isNeedaskPasswordForSend = [[[NSUserDefaults standardUserDefaults] objectForKey:askKey] boolValue];
    }
    else{
        _isNeedaskPasswordForSend = NO;
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:lockScreen]) {
        _lockScreenSeconds = [[[NSUserDefaults standardUserDefaults] objectForKey:lockScreen] intValue];
    }
    else{
        _lockScreenSeconds = 0;
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:biometricKey]) {
        _isEnableBiometric = [[[NSUserDefaults standardUserDefaults] objectForKey:biometricKey] boolValue];
    }
    else{
        _isEnableBiometric = YES;
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:hideAmountsKey]) {
        _isHideAmounts = [[[NSUserDefaults standardUserDefaults] objectForKey:hideAmountsKey] boolValue];
    }
    else{
        _isHideAmounts = NO;
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:askHideAmountsKey]) {
        _isAskForHideAmounts = [[[NSUserDefaults standardUserDefaults] objectForKey:askHideAmountsKey] boolValue];
    }
    else{
        _isAskForHideAmounts = YES;
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:alowOpenLinkKey]) {
        _isAllowOpenLink = [[[NSUserDefaults standardUserDefaults] objectForKey:alowOpenLinkKey] boolValue];
    }
    else{
        _isAllowOpenLink = NO;
    }
    
    if (self.target == Testnet) {
        _explorerAddress = @"https://testnet.explorer.beam.mw/";
    }
    else if (self.target == Masternet) {
        _explorerAddress = @"https://master-net.explorer.beam.mw/";
    }
    else{
        _explorerAddress = @"https://explorer.beam.mw/";
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:nodeKey]) {
        _nodeAddress = [[NSUserDefaults standardUserDefaults] objectForKey:nodeKey];
    }
    else{
        if (self.target == Testnet) {
            _nodeAddress = @"ap-node03.testnet.beam.mw:8100";
        }
        else if (self.target == Masternet) {
            _nodeAddress = @"eu-node03.masternet.beam.mw:8100";
        }
        else{
            _nodeAddress = @"ap-node01.mainnet.beam.mw:8100";
        }
    }
    
    
    if (self.target == Testnet)
    {
        [self copyOldDatabaseToGroup];
    }
    
    return self;
}

-(void)setIsHideAmounts:(BOOL)isHideAmounts {
    _isHideAmounts = isHideAmounts;
    
    for(id<SettingsModelDelegate> delegate in [Settings sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onChangeHideAmounts)]) {
            [delegate onChangeHideAmounts];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:_isHideAmounts forKey:hideAmountsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setIsEnableBiometric:(BOOL)isEnableBiometric {
    _isEnableBiometric = isEnableBiometric;

    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:_isEnableBiometric] forKey:biometricKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setLockScreenSeconds:(int)lockScreenSeconds {
    _lockScreenSeconds = lockScreenSeconds;
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:_lockScreenSeconds] forKey:lockScreen];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setIsNeedaskPasswordForSend:(BOOL)isNeedaskPasswordForSend {
    _isNeedaskPasswordForSend = isNeedaskPasswordForSend;
    
    [[NSUserDefaults standardUserDefaults] setBool:_isNeedaskPasswordForSend forKey:askKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setIsAskForHideAmounts:(BOOL)isAskForHideAmounts{
    _isAskForHideAmounts = isAskForHideAmounts;
    
    [[NSUserDefaults standardUserDefaults] setBool:isAskForHideAmounts forKey:askHideAmountsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setIsAllowOpenLink:(BOOL)isAllowOpenLink {
    _isAllowOpenLink = isAllowOpenLink;
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:_isAllowOpenLink] forKey:alowOpenLinkKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)isChangedNode {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:nodeKey]) {
        return YES;
    }
    return NO;
}


-(NSString*_Nonnull)walletStoragePath {
    if (self.target == Testnet) {
        return [self groupDBPath];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *oldPath = [documentsDirectory stringByAppendingPathComponent:@"/wallet1"];
    return oldPath;
}


-(void)setNodeAddress:(NSString *_Nonnull)nodeAddress {
    _nodeAddress = nodeAddress;
    
    [[NSUserDefaults standardUserDefaults] setObject:_nodeAddress forKey:nodeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onNetwotkStatusChange:)]) {
            [delegate onNetwotkStatusChange:NO];
        }
    }
}

-(NSString*_Nonnull)logPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/beam_logs"];
    return dataPath;
}

#pragma mark - Local Node

-(int)nodePort {
    if (self.target == Testnet) {
        return 11005;
    }
    else{
        return 10005;
    }
}

-(NSString*_Nonnull)localNodeStorage {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/node.db"];
    
    return dataPath;
}

-(NSString*_Nonnull)localNodeTemdDir {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    return documentsDirectory;
}

-(NSArray*_Nonnull)localNodePeers {
    if (self.target == Testnet) {
        return @[@"us-nodes.testnet.beam.mw:8100",@"eu-nodes.testnet.beam.mw:8100",@"ap-nodes.testnet.beam.mw:8100"];
    }
    else{
        return @[@"ap-nodes.mainnet.beam.mw:8100",@"eu-nodes.mainnet.beam.mw:8100",@"us-nodes.mainnet.beam.mw:8100"];
    }
}

-(NSString *)groupDBPath{
    NSString *documentsDirectory = [self groupPath];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/wallet1"];
    return dataPath;
}

-(void)copyOldDatabaseToGroup {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *oldPath = [documentsDirectory stringByAppendingPathComponent:@"/wallet1"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:oldPath]) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:[self groupDBPath]]) {
            [[NSFileManager defaultManager] copyItemAtPath:oldPath toPath:[self groupDBPath] error:nil];
        }
    }
}

-(NSString *)groupPath{
    NSString *groupId = @"";
    
    if (self.target == Testnet) {
        groupId = @"group.beamwallettestnet";
    }
    else if (self.target == Masternet) {
        groupId = @"group.beamwalletmasternet";
    }
    else{
        groupId = @"group.beamwalletmainnet";
    }
    
    NSString *appGroupDirectoryPath = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupId].path;
    
    return appGroupDirectoryPath;
}

#pragma mark - Delegates

-(void)addDelegate:(id<SettingsModelDelegate>) delegate{
    if(![_delegates containsObject:delegate])
    {
        [_delegates addObject: delegate];
    }
}

-(void)removeDelegate:(id<SettingsModelDelegate>) delegate {
    [_delegates removeObject: delegate];
}

@end
