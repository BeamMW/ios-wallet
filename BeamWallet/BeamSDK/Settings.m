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

+(NSArray*)walletStoragesPaths {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:allPathsKey] isKindOfClass:[NSNull class]]) {
        return [NSArray new];
    }
    
    return [NSArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:allPathsKey]];
}

+(void)generateNewStoragePath {
    NSString *name = [NSString stringWithFormat:@"%d",(int)[NSDate date].timeIntervalSince1970];
    
    NSMutableArray *paths = [NSMutableArray arrayWithArray:[Settings walletStoragesPaths]];
    [paths addObject:name];
    
    [[NSUserDefaults standardUserDefaults] setObject:name forKey:storageKey];
    [[NSUserDefaults standardUserDefaults] setObject:paths forKey:allPathsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


+(NSString*)walletStoragePath {
//    if ([[[NSUserDefaults standardUserDefaults] objectForKey:storageKey] isKindOfClass:[NSNull class]]) {
//        [Settings generateNewStoragePath];
//    }
//    
//   // NSString *name = [[NSUserDefaults standardUserDefaults] objectForKey:storageKey];
//    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/wallet1"];
    
    return dataPath;
}


+(NSString*)nodeAddress {
    return @"ap-node03.testnet.beam.mw:8100";
}

+(NSString*)logPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/beam_logs"];
    return dataPath;
}

@end
