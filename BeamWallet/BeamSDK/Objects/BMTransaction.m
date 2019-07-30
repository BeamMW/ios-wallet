//
// BMTransaction.m
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

#import "BMTransaction.h"
#import "StringLocalize.h"
#import "Settings.h"

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

-(NSString*)shortDate {
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:[Settings sharedManager].language];

    NSDateFormatter *f = [NSDateFormatter new];
    
    if ([[Settings sharedManager].language isEqualToString:@"zh-Hans"]) {
        [f setDateFormat:@"MMM dd"];
    }
    else{
        [f setDateFormat:@"dd MMM"];
    }
    [f setLocale:locale];

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_createdTime];
    
    return [f stringFromDate:date];
}

-(NSString*)formattedDate {
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:[Settings sharedManager].language];

    NSDateFormatter *f = [NSDateFormatter new];
    
    if ([[Settings sharedManager].language isEqualToString:@"zh-Hans"]) {
        [f setDateFormat:@"yyyy MMM dd  |  HH:mm"];
    }
    else{
        [f setDateFormat:@"dd MMM yyyy  |  HH:mm"];
    }
    
    [f setLocale:locale];

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_createdTime];
    
    return [f stringFromDate:date];
}
    
-(BOOL)isExpired {
    return  [self.status isEqualToString:[[@"expired" localized] lowercaseString]];
}

-(BOOL)isFailed {
    return [self.status isEqualToString:[[@"failed" localized] lowercaseString]] || [self.status isEqualToString:[[@"expired" localized] lowercaseString]];
}

-(BOOL)isCancelled {
    return [self.status isEqualToString:[[@"cancelled" localized] lowercaseString]];
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
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    formatter.numberStyle = NSNumberFormatterCurrencyAccountingStyle;
    
    NSString *number = [formatter stringFromNumber:[NSNumber numberWithDouble:_realAmount]];
    number = [number stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *detail = [NSString stringWithFormat:@"Sender: %@\nReceiver: %@\nAmount: %@ BEAM\nKernel ID: %@", _senderAddress, _receiverAddress, number, _kernelId];
    detail = [detail stringByReplacingOccurrencesOfString:@"  " withString:@" "];
    return detail;
}

-(NSString*)csvLine {    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.currencyCode = @"";
    formatter.currencySymbol = @"";
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 10;
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    formatter.numberStyle = NSNumberFormatterCurrencyAccountingStyle;
    
    NSString *_type =  self.isIncome ? @"Receive BEAM" : @"Send BEAM";
    NSString *_date =  [self formattedDate];
    NSString *_amount =  [[formatter stringFromNumber:[NSNumber numberWithDouble:_realAmount]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *_status = self.status;
    NSString *_sending = self.senderAddress;
    NSString *_receiving = self.receiverAddress;
    NSString *_fee =  [[formatter stringFromNumber:[NSNumber numberWithDouble:self.fee]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *_id = self.ID;
    NSString *_kernel = self.kernelId;
    
    NSArray *array = @[_type,_date,_amount,_status,_sending,_receiving,_fee,_id,_kernel];
    
    return [[array componentsJoinedByString:@","] stringByAppendingString:@"\n"];
}

-(BOOL)isNew {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_createdTime];
    NSDate *current = [NSDate date];
    
    int difference = current.timeIntervalSince1970 - date.timeIntervalSince1970;
    if (difference<5) {
        return YES;
    }
    
    return NO;
}


-(UIImage*)statusIcon {
    if (self.isCancelled)
    {
        return [UIImage imageNamed:@"icon-canceled"];
    }
    else if (self.isFailed)
    {
        return [UIImage imageNamed:@"icon-failed"];
    }
    else if(self.isExpired)
    {
        return [UIImage imageNamed:@"icon-failed"];
    }
    else if (_isSelf) {
        switch (_enumStatus) {
            case BMTransactionStatusPending:
                return [UIImage imageNamed:@"icon-sending-own"];
            case BMTransactionStatusInProgress:
                return [UIImage imageNamed:@"icon-sending-own"];
            case BMTransactionStatusRegistering:
                return [UIImage imageNamed:@"icon-sending-own"];
            case BMTransactionStatusCompleted:
                return [UIImage imageNamed:@"icon-sent-own"];
            default:
                return [UIImage imageNamed:@"icon-sent-own"];
        }
    }
    else if(_isIncome) {
        switch (_enumStatus) {
            case BMTransactionStatusPending:
                return [UIImage imageNamed:@"icon-receiving"];
            case BMTransactionStatusInProgress:
                return [UIImage imageNamed:@"icon-receiving"];
            case BMTransactionStatusCompleted:
                return [UIImage imageNamed:@"icon-received"];
            default:
                return [UIImage imageNamed:@"icon-received"];
        }
    }
    else{
        switch (_enumStatus) {
            case BMTransactionStatusPending:
                return [UIImage imageNamed:@"icon-icon-sending"];
            case BMTransactionStatusInProgress:
                return [UIImage imageNamed:@"icon-icon-sending"];
            case BMTransactionStatusCompleted:
                return [UIImage imageNamed:@"icon-sent"];
            default:
                return [UIImage imageNamed:@"icon-sent"];
        }
    }
    
    
    return [UIImage imageNamed:@"icon-sent"];
}

@end
