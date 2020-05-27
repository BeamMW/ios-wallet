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
#import "Color.h"
#import "BMAddress.h"
#import "AppModel.h"

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
        if ([[NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]] rangeOfString:@"a"].location!=NSNotFound) {
            [f setDateFormat:@"yyyy MMM dd  |  hh:mm a"];
        }
        else{
            [f setDateFormat:@"yyyy MMM dd  |  HH:mm"];
        }
    }
    else{
        if ([[NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]] rangeOfString:@"a"].location!=NSNotFound) {
            [f setDateFormat:@"dd MMM yyyy  |  hh:mm a"];
        }
        else{
            [f setDateFormat:@"dd MMM yyyy  |  HH:mm"];
        }
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

-(BOOL)isUnlink {
    return self.enumType == BMTransactionTypePullTransaction || self.enumType == BMTransactionTypePushTransaction;
}


-(UIImage*)statusIcon {
    if (self.enumType == BMTransactionTypePullTransaction || self.enumType == BMTransactionTypePushTransaction) {
        return [UIImage imageNamed:@"iconUnlinkedTransaction"];
    }
    else if (self.isCancelled)
    {
        if(_isIncome) {
            return [UIImage imageNamed:@"icnReceiveCanceled"];
        }
        else{
            return [UIImage imageNamed:@"icnSendCanceled"];
        }
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
            case BMTransactionStatusRegistering:
                return [UIImage imageNamed:@"icon-receiving"];
            case BMTransactionStatusCompleted:
                return [UIImage imageNamed:@"icon-received"];
            default:
                return [UIImage imageNamed:@"icon-receiving"];
        }
    }
    else{
        switch (_enumStatus) {
            case BMTransactionStatusRegistering:
                return [UIImage imageNamed:@"icon-icon-sending"];
            case BMTransactionStatusPending:
                return [UIImage imageNamed:@"icon-icon-sending"];
            case BMTransactionStatusInProgress:
                return [UIImage imageNamed:@"icon-icon-sending"];
            case BMTransactionStatusCompleted:
                return [UIImage imageNamed:@"icon-sent"];
            default:
                return [UIImage imageNamed:@"icon-icon-sending"];
        }
    }
    
    
    return [UIImage imageNamed:@"icon-sent"];
}


-(NSMutableAttributedString*)searchString:(NSString*)searchText{
    NSMutableArray *strings = [NSMutableArray array];
            
    NSRange idRange = NSMakeRange(NSNotFound, NSNotFound);
    NSRange kernelRange = NSMakeRange(NSNotFound, NSNotFound);
    NSRange senderAddressRange = NSMakeRange(NSNotFound, NSNotFound);
    NSRange receiverAddressRange = NSMakeRange(NSNotFound, NSNotFound);
    NSRange commentRange = NSMakeRange(NSNotFound, NSNotFound);
    NSRange senderNameRange = NSMakeRange(NSNotFound, NSNotFound);
    NSRange receiverNameRange = NSMakeRange(NSNotFound, NSNotFound);

    if ([_ID.lowercaseString hasPrefix:searchText.lowercaseString]) {
        idRange = [_ID.lowercaseString rangeOfString:searchText.lowercaseString];
    }
    
    if ([_kernelId.lowercaseString hasPrefix:searchText.lowercaseString]) {
        kernelRange = [_kernelId.lowercaseString rangeOfString:searchText.lowercaseString];
    }
    
    if ([_senderAddress.lowercaseString hasPrefix:searchText.lowercaseString]) {
        senderAddressRange = [_senderAddress.lowercaseString rangeOfString:searchText.lowercaseString];
    }
    
    if ([_receiverAddress.lowercaseString hasPrefix:searchText.lowercaseString]) {
        receiverAddressRange = [_receiverAddress.lowercaseString rangeOfString:searchText.lowercaseString];
    }
    
    if ([_comment.lowercaseString hasPrefix:searchText.lowercaseString]) {
        commentRange = [_comment.lowercaseString rangeOfString:searchText.lowercaseString];
    }
    
    if ([_senderContactName.lowercaseString hasPrefix:searchText.lowercaseString]) {
        senderNameRange = [_senderContactName.lowercaseString rangeOfString:searchText.lowercaseString];
    }
    
    if ([_receiverContactName.lowercaseString hasPrefix:searchText.lowercaseString]) {
        receiverNameRange = [_receiverContactName.lowercaseString rangeOfString:searchText.lowercaseString];
    }

    CGFloat fontsize = 14;
    
    if ([UIScreen mainScreen].bounds.size.height < 600) {
        fontsize = fontsize - 1.5f;
    }
    else if ([UIScreen mainScreen].bounds.size.height > 736) {
        fontsize = fontsize + 1;
    }
    

    UIFont *font = [UIFont fontWithName:@"SFProDisplay-Bold" size:fontsize];
    
    if (_comment.length > 0) {
        NSTextAttachment *attach = [[NSTextAttachment alloc] init];
        attach.image = [UIImage imageNamed:@"iconComment"];
        attach.bounds = CGRectMake(0, -3, 16, 16);
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"”%@”",_comment]];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#8DA1AD"] range:NSMakeRange(0, string.string.length)];
        [string addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"SFProDisplay-Italic" size:fontsize] range:NSMakeRange(0, string.string.length)];

        if (commentRange.location!=NSNotFound) {
            [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#00F6D2"] range:NSMakeRange(commentRange.location+1, commentRange.length)];
        }

        NSMutableAttributedString *commentString = [[NSMutableAttributedString alloc] init];
        [commentString appendAttributedString:[NSMutableAttributedString attributedStringWithAttachment:attach]];
        [commentString appendAttributedString:[[NSAttributedString alloc]initWithString:@"   "]];
        [commentString appendAttributedString:string];
        
        [strings addObject:commentString];
    }
    
    if (idRange.location!=NSNotFound) {
        NSString *localizable = [@"transaction_id" localized];
        
        NSMutableAttributedString *localizableString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", localizable]];
        [localizableString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#8DA1AD"] range:NSMakeRange(0, localizableString.string.length)];
        [localizableString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, localizableString.string.length)];
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",_ID]];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#8DA1AD"] range:NSMakeRange(0, string.string.length)];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#00F6D2"] range:[string.string.lowercaseString rangeOfString:searchText.lowercaseString]];
        
        NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
        [result appendAttributedString:localizableString];
        [result appendAttributedString:string];

        [strings addObject:result];
    }
    
    if (kernelRange.location!=NSNotFound) {
        NSString *localizable = [@"kernel_id" localized];
        
        NSMutableAttributedString *localizableString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", localizable]];
        [localizableString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#8DA1AD"] range:NSMakeRange(0, localizableString.string.length)];
        [localizableString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, localizableString.string.length)];
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",_kernelId]];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#8DA1AD"] range:NSMakeRange(0, string.string.length)];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#00F6D2"] range:[string.string.lowercaseString rangeOfString:searchText.lowercaseString]];
        
        NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
        [result appendAttributedString:localizableString];
        [result appendAttributedString:string];
        
        [strings addObject:result];
    }
    
    if (senderAddressRange.location!=NSNotFound) {
        NSString *localizable = [@"sender" localized];
        
        NSMutableAttributedString *localizableString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", localizable]];
        [localizableString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#8DA1AD"] range:NSMakeRange(0, localizableString.string.length)];
        [localizableString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, localizableString.string.length)];
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",_senderAddress]];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#8DA1AD"] range:NSMakeRange(0, string.string.length)];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#00F6D2"] range:[string.string.lowercaseString rangeOfString:searchText.lowercaseString]];
        
        NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
        [result appendAttributedString:localizableString];
        [result appendAttributedString:string];
        
        [strings addObject:result];
    }
    
    if (receiverAddressRange.location!=NSNotFound) {
        NSString *localizable = [@"receiver" localized];
        
        NSMutableAttributedString *localizableString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", localizable]];
        [localizableString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#8DA1AD"] range:NSMakeRange(0, localizableString.string.length)];
        [localizableString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, localizableString.string.length)];
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",_receiverAddress]];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#8DA1AD"] range:NSMakeRange(0, string.string.length)];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#00F6D2"] range:[string.string.lowercaseString rangeOfString:searchText.lowercaseString]];
        
        NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
        [result appendAttributedString:localizableString];
        [result appendAttributedString:string];
        
        [strings addObject:result];
    }
    
    if (senderNameRange.location!=NSNotFound) {
        NSTextAttachment *attach = [[NSTextAttachment alloc] init];
        attach.image = [UIImage imageNamed:@"iconContact"];
        attach.bounds = CGRectMake(0, -3, 16, 16);

        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",_senderContactName]];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#8DA1AD"] range:NSMakeRange(0, string.string.length)];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#00F6D2"] range:senderNameRange];
        [string addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, string.string.length)];

        NSMutableAttributedString *commentString = [[NSMutableAttributedString alloc] init];
        [commentString appendAttributedString:[NSMutableAttributedString attributedStringWithAttachment:attach]];
        [commentString appendAttributedString:[[NSAttributedString alloc]initWithString:@"    "]];
        [commentString appendAttributedString:string];
        
        [strings addObject:commentString];
    }
    
    if (receiverNameRange.location!=NSNotFound) {
        NSTextAttachment *attach = [[NSTextAttachment alloc] init];
        attach.image = [UIImage imageNamed:@"iconContact"];
        attach.bounds = CGRectMake(0, -3, 16, 16);

        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",_receiverContactName]];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#8DA1AD"] range:NSMakeRange(0, string.string.length)];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#00F6D2"] range:receiverNameRange];
        [string addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, string.string.length)];
        
        NSMutableAttributedString *commentString = [[NSMutableAttributedString alloc] init];
        [commentString appendAttributedString:[NSMutableAttributedString attributedStringWithAttachment:attach]];
        [commentString appendAttributedString:[[NSAttributedString alloc]initWithString:@"    "]];
        [commentString appendAttributedString:string];
        
        [strings addObject:commentString];
    }
    
    if (_comment.length > 0 && strings.count > 1) {
        NSMutableAttributedString *str = strings[0];
        
        NSMutableAttributedString *space = [[NSMutableAttributedString alloc]initWithString:@"\nspace\n"];
        [space addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:4] range:NSMakeRange(0, space.string.length)];
        [space addAttribute:NSForegroundColorAttributeName value:[UIColor clearColor] range:NSMakeRange(0, space.string.length)];
        
        [str appendAttributedString:space];
        
        [strings replaceObjectAtIndex:0 withObject:str];
    }
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    
    for (NSMutableAttributedString *str in strings) {
        [attributedString appendAttributedString:str];
        if (strings.lastObject!=str) {
            NSMutableAttributedString *space = [[NSMutableAttributedString alloc]initWithString:@"\nspace\n"];
            [space addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:4] range:NSMakeRange(0, space.string.length)];
            [space addAttribute:NSForegroundColorAttributeName value:[UIColor clearColor] range:NSMakeRange(0, space.string.length)];
            
            [attributedString appendAttributedString:space];
        }
    }
    
    return attributedString;
}

-(BOOL)canSaveContact {
    if (self.isIncome) {
        BMAddress *address = [[AppModel sharedManager] findAddressByID:_senderAddress];
        return address == nil;
    }
    else{
        BMAddress *address = [[AppModel sharedManager] findAddressByID:_receiverAddress];
        return address == nil;
    }
    return NO;
}

-(NSString*)textDetails {
    NSMutableArray *details = [NSMutableArray array];
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.currencyCode = @"";
    formatter.currencySymbol = @"";
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 10;
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    formatter.numberStyle = NSNumberFormatterCurrencyAccountingStyle;
    
    NSString *number = [formatter stringFromNumber:[NSNumber numberWithDouble:_realAmount]];
    number = [number stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *date = [NSString stringWithFormat:@"%@\n%@",[[@"date" localized]uppercaseString], [self formattedDate]];
    
    NSString *amount = [NSString stringWithFormat:@"%@\n%@",[[@"amount" localized]uppercaseString], [NSString stringWithFormat:@"%@ BEAM",number]];
    
    NSString *status = [NSString stringWithFormat:@"%@\n%@",[[@"status" localized]uppercaseString], _status];
    
    NSString *sender;
    NSString *receiver;

    if (_isSelf) {
        sender = [NSString stringWithFormat:@"%@\n%@",[[@"my_send_address" localized]uppercaseString], _senderAddress];
        receiver = [NSString stringWithFormat:@"%@\n%@",[[@"my_rec_address" localized]uppercaseString], _receiverAddress];
    }
    else if(_isIncome)
    {
        sender = [NSString stringWithFormat:@"%@\n%@",[[@"contact" localized]uppercaseString], _senderAddress];
        receiver = [NSString stringWithFormat:@"%@\n%@",[[@"my_address" localized]uppercaseString], _receiverAddress];
    }
    else{
        sender = [NSString stringWithFormat:@"%@\n%@",[[@"contact" localized]uppercaseString], _receiverAddress];
        receiver = [NSString stringWithFormat:@"%@\n%@",[[@"my_address" localized]uppercaseString], _senderAddress];
    }

    NSString *fee = [NSString stringWithFormat:@"%@\n%@",[[@"transaction_fee" localized]uppercaseString], [NSString stringWithFormat:@"%llu GROTH",_realFee]];
                      
    NSString *trid = [NSString stringWithFormat:@"%@\n%@",[[@"transaction_id" localized]uppercaseString], _ID];

    [details addObject:date];
    [details addObject:status];
    [details addObject:amount];
    [details addObject:sender];
    [details addObject:receiver];
    [details addObject:fee];
    [details addObject:trid];

    
    NSString *kernel = [NSString stringWithFormat:@"%@\n%@",[[@"kernel_id" localized]uppercaseString], _ID];

    if (!self.isExpired && !self.isFailed && ![_kernelId hasPrefix:@"00000"]) {
        [details addObject:kernel];
    }

    
    if ([self isFailed]) {
        NSString *failed = [NSString stringWithFormat:@"%@\n%@",[[@"failure_reason" localized]uppercaseString], _failureReason];
        [details addObject:failed];
    }
           
    return [details componentsJoinedByString:@"\n\n"];
}

@end
