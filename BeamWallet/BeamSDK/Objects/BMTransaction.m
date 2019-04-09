//
//  BMTransaction.m
//  BeamWallet
//
// 3/5/19.
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

#import "BMTransaction.h"

@implementation BMTransaction

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.ID forKey: @"ID"];
    [encoder encodeObject:self.status forKey: @"status"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isIncome] forKey: @"isIncome"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isSelf] forKey: @"isSelf"];
    [encoder encodeObject:[NSNumber numberWithDouble:self.realAmount] forKey: @"realAmount"];
    [encoder encodeObject:[NSNumber numberWithInteger:self.enumStatus] forKey: @"enumStatus"];
}

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if(self)
    {
        self.ID = [decoder decodeObjectForKey: @"ID"];
        self.status = [decoder decodeObjectForKey: @"status"];
        self.isIncome = [[decoder decodeObjectForKey:@"isIncome"] boolValue];
        self.isSelf = [[decoder decodeObjectForKey:@"isSelf"] boolValue];
        self.realAmount = [[decoder decodeObjectForKey:@"realAmount"] boolValue];
        self.enumStatus = [[decoder decodeObjectForKey:@"enumStatus"] integerValue];
    }
    return self;
}

-(NSString*)formattedDate {
    NSDateFormatter *f = [NSDateFormatter new];
    [f setDateFormat:@"dd MMM yyyy  |  HH:mm"];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_createdTime];
    
    return [f stringFromDate:date];
}

-(BOOL)isFailed {
    return [self.status isEqualToString:@"failed"];
}

-(BOOL)hasPaymentProof {
    return (self.isIncome == NO && self.enumStatus == BMTransactionStatusCompleted && self.isSelf == NO);
}

-(NSString*)details {
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.currencyCode = @"";
    formatter.currencySymbol = @"";
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 10;
    formatter.numberStyle = NSNumberFormatterCurrencyAccountingStyle;
    
    return [NSString stringWithFormat:@"Sender: %@\nReceiver: %@\nAmount: %@\nKernel ID: %@", _senderAddress, _receiverAddress, [formatter stringFromNumber:[NSNumber numberWithDouble:_realAmount]], _kernelId];
}

@end
