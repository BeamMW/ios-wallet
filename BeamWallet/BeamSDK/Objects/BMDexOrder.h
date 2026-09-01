//
//  BMDexOrder.h
//  BeamWallet
//
// Copyright 2026 Beam Development
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

@interface BMDexOrder : NSObject

@property (nonatomic, strong) NSString * _Nonnull orderID;
@property (nonatomic, strong) NSString * _Nonnull sbbsID;

@property (nonatomic, assign) UInt32 sendAssetId;
@property (nonatomic, assign) UInt32 receiveAssetId;

@property (nonatomic, strong) NSString * _Nonnull sendAssetSName;
@property (nonatomic, strong) NSString * _Nonnull receiveAssetSName;

@property (nonatomic, assign) UInt64 sendAmount;
@property (nonatomic, assign) UInt64 receiveAmount;

@property (nonatomic, assign) UInt64 createTimestamp;
@property (nonatomic, assign) UInt64 expireTimestamp;

@property (nonatomic, assign) BOOL isMine;
@property (nonatomic, assign) BOOL isAccepted;
@property (nonatomic, assign) BOOL isCanceled;
@property (nonatomic, assign) BOOL isCompleted;

-(BOOL)isExpired;
-(BOOL)isActive;

-(NSString * _Nonnull)displayCreatedDate;
-(NSString * _Nonnull)displayExpiresIn;
-(NSString * _Nonnull)displaySendAmount;
-(NSString * _Nonnull)displayReceiveAmount;
-(NSString * _Nonnull)displayRate;
-(NSString * _Nonnull)displayStatus;

@end
