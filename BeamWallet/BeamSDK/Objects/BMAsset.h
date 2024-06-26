//
// BMAsset.h
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

@interface BMAsset : NSObject <NSSecureCoding, NSCopying> {
    
    
}

@property (nonatomic,strong) NSString  * _Nonnull unitName;
@property (nonatomic,strong) NSString  * _Nonnull nthUnitName;
@property (nonatomic,strong) NSString  * _Nonnull shortName;
@property (nonatomic,strong) NSString  * _Nonnull shortDesc;
@property (nonatomic,strong) NSString  * _Nonnull longDesc;
@property (nonatomic,strong) NSString  * _Nonnull name;
@property (nonatomic,strong) NSString  * _Nonnull color;
@property (nonatomic,strong) NSString  * _Nullable site;
@property (nonatomic,strong) NSString  * _Nullable paper;
@property (nonatomic,assign) UInt64 assetId;

@property (nonatomic,assign) UInt64 available;
@property (nonatomic,assign) UInt64 receiving;
@property (nonatomic,assign) UInt64 sending;
@property (nonatomic,assign) UInt64 maturing;
@property (nonatomic,assign) UInt64 shielded;
@property (nonatomic,assign) UInt64 maxPrivacy;

@property (nonatomic,assign) double realAmount;
@property (nonatomic,assign) double realReceiving;
@property (nonatomic,assign) double realSending;
@property (nonatomic,assign) double realMaturing;
@property (nonatomic,assign) double realShielded;
@property (nonatomic,assign) double realMaxPrivacy;

-(UInt64)locked;
-(double)realLocked;

-(UInt64)change;
-(double)realChange;

-(BOOL)isBeam;
-(BOOL)isBeamX;

-(double)USD;
-(UInt64)dateUsed;
-(BOOL)isIncomming;

@end
