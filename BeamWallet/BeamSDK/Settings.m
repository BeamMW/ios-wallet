//
//  Settings.m
//  BeamTest
//
// 2/28/19.
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

@implementation Settings

static NSString *storageKey = @"storageKey";
static NSString *allPathsKey = @"allPaths";
static NSString *askKey = @"isNeedaskPasswordForSend";
static NSString *lockScreen = @"lockScreen";
static NSString *biometricKey = @"biometricKey";

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
        _isEnableBiometric = [[[NSUserDefaults standardUserDefaults] objectForKey:askKey] boolValue];
    }
    else{
        _isEnableBiometric = YES;
    }
    
    return self;
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

-(NSArray*_Nonnull)walletStoragesPaths {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:allPathsKey] isKindOfClass:[NSNull class]]) {
        return [NSArray new];
    }
    
    return [NSArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:allPathsKey]];
}

-(void)generateNewStoragePath {
    NSString *name = [NSString stringWithFormat:@"%d",(int)[NSDate date].timeIntervalSince1970];
    
    NSMutableArray *paths = [NSMutableArray arrayWithArray:[[Settings sharedManager] walletStoragesPaths]];
    [paths addObject:name];
    
    [[NSUserDefaults standardUserDefaults] setObject:name forKey:storageKey];
    [[NSUserDefaults standardUserDefaults] setObject:paths forKey:allPathsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(NSString*_Nonnull)walletStoragePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/wallet1"];
    
    return dataPath;
}


-(NSString*_Nonnull)nodeAddress {
    NSString *target =  [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"];
    
    if ([target isEqualToString:@"BeamWalletTestNet"]) {
        return @"ap-node03.testnet.beam.mw:8100";
    }
    else{
        return @"ap-node01.mainnet.beam.mw:8100";
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
    NSString *target =  [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"];
    
    if ([target isEqualToString:@"BeamWalletTestNet"]) {
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
    NSString *target =  [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"];
    
    if ([target isEqualToString:@"BeamWalletTestNet"]) {
        return @[@"us-nodes.testnet.beam.mw:8100",@"eu-nodes.testnet.beam.mw:8100",@"ap-nodes.testnet.beam.mw:8100"];
    }
    else{
        return @[@"ap-nodes.mainnet.beam.mw:8100",@"eu-nodes.mainnet.beam.mw:8100",@"us-nodes.mainnet.beam.mw:8100"];
    }
}

@end
