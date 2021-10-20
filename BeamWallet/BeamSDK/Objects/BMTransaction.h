//
// BMTransaction.h
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
#import "BMAsset.h"
#import <UIKit/UIKit.h>

enum {
    BMTransactionStatusPending = 0,
    BMTransactionStatusInProgress = 1,
    BMTransactionStatusCancelled = 2,
    BMTransactionStatusCompleted = 3,
    BMTransactionStatusFailed = 4,
    BMTransactionStatusRegistering = 5
};
typedef UInt64 BMTransactionStatus;

enum {
    BMTransactionTypeSimple = 0,
    BMTransactionTypeAtomicSwap = 1,
    BMTransactionTypeAssetIssue = 2,
    BMTransactionTypeAssetConsume = 3,
    BMTransactionTypeAssetReg = 4,
    BMTransactionTypeAssetUnreg = 5,
    BMTransactionTypeAssetInfo = 6,
    BMTransactionTypePushTransaction = 7,
    BMTransactionTypePullTransaction = 8,
    BMTransactionTypeVoucherRequest = 9,
    BMTransactionTypeVoucherResponse = 10,
    BMTransactionTypeUnlink = 11,
    BMTransactionTypeALL = 12
};
typedef UInt64 BMTransactionType;


@interface BMTransaction : NSSecureUnarchiveFromDataTransformer <NSSecureCoding> {
}

@property (nonatomic,strong) NSString *_Nonnull ID;
@property (nonatomic,assign) UInt64 createdTime;
@property (nonatomic,strong) NSString * _Nonnull status;
@property (nonatomic,strong) NSString * _Nonnull failureReason;
@property (nonatomic,strong) NSString * _Nonnull kernelId;
@property (nonatomic,strong) NSString * _Nonnull senderAddress;
@property (nonatomic,strong) NSString * _Nonnull receiverAddress;
@property (nonatomic,strong) NSString * _Nonnull comment;
@property (nonatomic,assign) BOOL isIncome;
@property (nonatomic,assign) BOOL isSelf;
@property (nonatomic,assign) BOOL canCancel;
@property (nonatomic,assign) BOOL canResume;
@property (nonatomic,assign) BOOL canDelete;
@property (nonatomic,assign) BOOL isPublicOffline;
@property (nonatomic,assign) BOOL isShielded;
@property (nonatomic,assign) BOOL isMaxPrivacy;
@property (nonatomic,assign) BOOL isDapps;
@property (nonatomic,assign) double fee;
@property (nonatomic,assign) double realAmount;
@property (nonatomic,assign) UInt64 realFee;
@property (nonatomic,assign) UInt64 realRate;
@property (nonatomic,assign) BMTransactionStatus enumStatus;
@property (nonatomic,assign) BMTransactionType enumType;
@property (nonatomic,assign) int assetId;
@property (nonatomic,strong) BMAsset * _Nullable asset;

@property (nonatomic,strong) NSString * _Nonnull senderContactName;
@property (nonatomic,strong) NSString * _Nonnull receiverContactName;

@property (nonatomic,strong) NSString * _Nonnull identity;
@property (nonatomic,strong) NSString * _Nonnull token;

@property (nonatomic,strong) NSString * _Nonnull senderIdentity;
@property (nonatomic,strong) NSString * _Nonnull receiverIdentity;

@property (nonatomic,strong) NSString * _Nullable appName;
@property (nonatomic,strong) NSString * _Nullable appID;
@property (nonatomic,strong) NSString * _Nullable contractCids;
@property (nonatomic,strong) NSString * _Nullable minConfirmations;
@property (nonatomic,strong) NSString * _Nullable minConfirmationsProgress;


-(NSString*_Nonnull)amountString;
-(UIImage*_Nonnull)statusIcon;
-(NSString*_Nonnull)statusName;
-(NSString*_Nonnull)statusType;
-(NSString*_Nonnull)getAddressType;

-(NSString*_Nonnull)formattedDate;
-(NSString*_Nonnull)shortDate;
-(BOOL)isFailed;
-(BOOL)hasPaymentProof;
-(BOOL)isCancelled;
-(BOOL)isNew;
-(BOOL)isExpired;
-(BOOL)canSaveContact;

-(NSString*_Nonnull)details;
-(NSString*_Nonnull)csvLine;
-(NSString*_Nonnull)textDetails;

-(NSString*_Nonnull)source;

-(NSMutableAttributedString*_Nonnull)searchString:(NSString*_Nonnull)searchText;

@end

