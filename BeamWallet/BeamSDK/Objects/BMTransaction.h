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

enum {
    BMTransactionStatusPending = 0,
    BMTransactionStatusInProgress = 1,
    BMTransactionStatusCancelled = 2,
    BMTransactionStatusCompleted = 3,
    BMTransactionStatusFailed = 4,
    BMTransactionStatusRegistering = 5
};
typedef UInt64 BMTransactionStatus;

@interface BMTransaction : NSObject

@property (nonatomic,strong) NSString *ID;
@property (nonatomic,assign) UInt64 createdTime;
@property (nonatomic,strong) NSString *status;
@property (nonatomic,strong) NSString *failureReason;
@property (nonatomic,strong) NSString *kernelId;
@property (nonatomic,strong) NSString *senderAddress;
@property (nonatomic,strong) NSString *receiverAddress;
@property (nonatomic,strong) NSString *comment;
@property (nonatomic,assign) BOOL isIncome;
@property (nonatomic,assign) BOOL isSelf;
@property (nonatomic,assign) BOOL canCancel;
@property (nonatomic,assign) BOOL canResume;
@property (nonatomic,assign) BOOL canDelete;
@property (nonatomic,assign) double fee;
@property (nonatomic,assign) double realAmount;
@property (nonatomic,assign) UInt64 realFee;
@property (nonatomic,assign) BMTransactionStatus enumStatus;

    
-(NSString*)formattedDate;
-(BOOL)isFailed;
-(BOOL)hasPaymentProof;
-(BOOL)isCancelled;
-(BOOL)isNew;

-(NSString*)details;
-(NSString*)csvLine;

@end

