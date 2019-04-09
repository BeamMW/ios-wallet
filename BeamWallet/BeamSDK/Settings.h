//
//  Settings.h
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

#import <Foundation/Foundation.h>

@interface Settings : NSObject

+(Settings*_Nonnull)sharedManager;

@property (nonatomic, assign) BOOL isLocalNode;
@property (nonatomic, assign) BOOL isNeedaskPasswordForSend;
@property (nonatomic, assign) int lockScreenSeconds;

//+(void)generateNewStoragePath;
//+(NSArray*)walletStoragesPaths;

-(NSString*_Nonnull)walletStoragePath;
-(NSString*_Nonnull)nodeAddress;

-(NSString*_Nonnull)logPath;

-(int)nodePort;
-(NSString*_Nonnull)localNodeStorage;
-(NSString*_Nonnull)localNodeTemdDir;
-(NSArray*_Nonnull)localNodePeers;

@end
