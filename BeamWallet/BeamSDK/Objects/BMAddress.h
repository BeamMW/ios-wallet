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

enum {
    BMAddressTypeRegular = 0,
    BMAddressTypeMaxPrivacy = 1,
    BMAddressTypeShielded = 2,
    BMAddressTypeOfflinePublic = 3,
    BMAddressTypeRegularPermanent = 4,
    BMAddressTypeUnknown = 5
};
typedef int BMAddressType;

@interface BMAddress : NSObject {
    NSDateFormatter *_formatter;
    NSDateFormatter *_shortFormatter;
}

+(BMAddress*_Nonnull)fromAddress:(BMAddress*_Nonnull)address;
+(BMAddress*_Nonnull)emptyAddress;

@property (nonatomic,strong, getter = getWalletId) NSString * _Nonnull walletId;
@property (nonatomic,strong) NSString * _Nullable offlineToken;
@property (nonatomic,strong) NSString * _Nullable maxPrivacyToken;
@property (nonatomic,strong) NSString * _Nullable address;

@property (nonatomic,strong) NSString * _Nonnull label;
@property (nonatomic,strong) NSString * _Nullable identity;

@property (nonatomic,assign) UInt64 createTime;
@property (nonatomic,assign) UInt64 duration;
@property (nonatomic,assign) UInt64 ownerId;
@property (nonatomic,assign) BOOL isDefault;

//edit
@property (nonatomic,assign) BOOL isNowExpired;
@property (nonatomic,assign) BOOL isNowActive;
@property (nonatomic,assign) UInt64 isNowActiveDuration;
@property (nonatomic,assign) BOOL isChangedDate;
@property (nonatomic,assign) BOOL isNeedRemoveTransactions;
@property (nonatomic,assign) BOOL isContact;

@property (nonatomic,getter=getMainId) NSString * _Nonnull _id;

-(BOOL)isExpired;
-(UInt64)getExpirationTime;
-(NSString* _Nonnull)formattedDate;
-(NSString* _Nonnull)expiredFormattedDate;
-(NSString* _Nonnull)agoDate;

//edit
-(NSString* _Nonnull)nowDate;
-(NSString* _Nonnull)expireNowDate;
-(int)isNowActiveDurationInHours;
-(int)durationInHours;

@end
