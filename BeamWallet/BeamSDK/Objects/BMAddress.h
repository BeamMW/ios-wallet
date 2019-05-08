//
//  BMAddress.h
//  BeamWallet
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

@interface BMAddress : NSObject {
    NSDateFormatter *_formatter;
}

@property (nonatomic,strong) NSString *walletId;
@property (nonatomic,strong) NSString *label;
@property (nonatomic,strong) NSString *category;
@property (nonatomic,assign) UInt64 createTime;
@property (nonatomic,assign) UInt64 duration;
@property (nonatomic,assign) UInt64 ownerId;

//edit
@property (nonatomic,assign) BOOL isNowExpired;
@property (nonatomic,assign) BOOL isNowActive;
@property (nonatomic,assign) UInt64 isNowActiveDuration;
@property (nonatomic,assign) BOOL isChangedDate;

-(BOOL)isExpired;
-(UInt64)getExpirationTime;
-(NSString*)formattedDate;

//edit
-(NSString*)nowDate;
-(NSString*)expireNowDate;
-(int)isNowActiveDurationInHours;
-(int)durationInHours;

@end
