//
//  BMUTXO.h
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

@class BMTransaction;

enum {
    BMUTXOUnavailable = 0,
    BMUTXOAvailable = 1,
    BMUTXOMaturing = 2,
    BMUTXOOutgoing = 3,
    BMUTXOIncoming = 4,
    BMUTXOChangeV0 = 5,
    BMUTXOSpent = 6
};
typedef int BMUTXOStatus;

@interface BMUTXO : NSObject

@property (nonatomic,assign) UInt64 ID;
@property (nonatomic,assign) UInt64 txoID;
@property (nonatomic,assign) UInt64 amount;
@property (nonatomic,assign) UInt64 time;
@property (nonatomic,assign) UInt64 user;
@property (nonatomic,assign) double realAmount;
@property (nonatomic,assign) BMUTXOStatus status;
@property (nonatomic,assign) UInt64 maturity;
@property (nonatomic,assign) UInt64 confirmHeight;
@property (nonatomic,strong) NSString * _Nonnull statusString;
@property (nonatomic,strong) NSString * _Nonnull stringID;
@property (nonatomic,strong) NSString * _Nonnull typeString;
@property (nonatomic,strong) NSString * _Nullable createTxId;
@property (nonatomic,strong) NSString * _Nullable spentTxId;
@property (nonatomic,strong) BMTransaction * _Nullable transaction;
@property (nonatomic,assign) UInt64 transactionDate;
@property (nonatomic,assign) BOOL isShilded;
@property (nonatomic,strong) NSString * _Nullable hoursLeft;


-(NSMutableAttributedString*_Nonnull)attributedStatus;

@end

