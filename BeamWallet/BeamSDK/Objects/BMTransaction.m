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

+ (BOOL)supportsSecureCoding {
    return NO;
}

+(NSArray<Class>*)allowedTopLevelClasses {
    return @[NSArray.class, NSString.class, NSNumber.class, BMAsset.class];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.ID forKey: @"ID"];
    [encoder encodeObject:self.status forKey: @"status"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isIncome] forKey: @"isIncome"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isSelf] forKey: @"isSelf"];
    [encoder encodeObject:[NSNumber numberWithDouble:self.realAmount] forKey: @"realAmount"];
    [encoder encodeObject:[NSNumber numberWithInteger:self.enumStatus] forKey: @"enumStatus"];
    [encoder encodeObject:[NSNumber numberWithInteger:self.enumType] forKey: @"enumType"];
    [encoder encodeObject:[NSNumber numberWithLongLong:self.createdTime] forKey: @"createdTime"];
    [encoder encodeObject:[NSNumber numberWithInteger:self.assetId] forKey: @"assetId"];
    
    [encoder encodeObject:[NSNumber numberWithDouble:self.fee] forKey: @"fee"];
    [encoder encodeObject:[NSNumber numberWithLongLong:self.realFee] forKey: @"realFee"];
    [encoder encodeObject:[NSNumber numberWithLongLong:self.realRate] forKey: @"realRate"];
    
    [encoder encodeObject:self.senderIdentity forKey: @"senderIdentity"];
    [encoder encodeObject:self.receiverIdentity forKey: @"receiverIdentity"];
    
    [encoder encodeObject:self.senderAddress forKey: @"senderAddress"];
    [encoder encodeObject:self.receiverAddress forKey: @"receiverAddress"];
    
    [encoder encodeObject:self.comment forKey: @"comment"];
    [encoder encodeObject:self.failureReason forKey: @"failureReason"];
    [encoder encodeObject:self.kernelId forKey: @"kernelId"];

    [encoder encodeObject:self.senderContactName forKey: @"senderContactName"];
    [encoder encodeObject:self.receiverContactName forKey: @"receiverContactName"];
    [encoder encodeObject:self.identity forKey: @"identity"];
    [encoder encodeObject:self.asset forKey: @"asset"];
    
    [encoder encodeObject:[NSNumber numberWithBool:self.isMaxPrivacy] forKey: @"isMaxPrivacy"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isPublicOffline] forKey: @"isPublicOffline"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isShielded] forKey: @"isShielded"];
    [encoder encodeObject:self.token forKey: @"token"];
    
    [encoder encodeObject:[NSNumber numberWithBool:self.isDapps] forKey: @"isDapps"];
    
    [encoder encodeObject:self.minConfirmations forKey: @"minConfirmations"];
    [encoder encodeObject:self.minConfirmationsProgress forKey: @"minConfirmationsProgress"];
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
        self.enumType = [[decoder decodeObjectForKey:@"enumType"] integerValue];
        self.createdTime = [[decoder decodeObjectForKey:@"createdTime"] longLongValue];

        self.fee = [[decoder decodeObjectForKey:@"fee"] doubleValue];
        self.realFee = [[decoder decodeObjectForKey:@"realFee"] longLongValue];

        self.realRate =  [[decoder decodeObjectForKey:@"realRate"] longLongValue];
        
        self.senderAddress = [decoder decodeObjectForKey: @"senderAddress"];
        self.receiverAddress = [decoder decodeObjectForKey: @"receiverAddress"];
        
        self.senderIdentity = [decoder decodeObjectForKey: @"senderIdentity"];
        self.receiverIdentity = [decoder decodeObjectForKey: @"receiverIdentity"];
        
        self.comment = [decoder decodeObjectForKey: @"comment"];
        self.failureReason = [decoder decodeObjectForKey: @"failureReason"];
        self.kernelId = [decoder decodeObjectForKey: @"kernelId"];

        self.senderContactName = [decoder decodeObjectForKey: @"senderContactName"];
        self.receiverContactName = [decoder decodeObjectForKey: @"receiverContactName"];
        self.identity = [decoder decodeObjectForKey: @"identity"];
        
        self.isMaxPrivacy = [[decoder decodeObjectForKey:@"isMaxPrivacy"] boolValue];
        self.isPublicOffline = [[decoder decodeObjectForKey:@"isPublicOffline"] boolValue];
        self.isShielded = [[decoder decodeObjectForKey:@"isShielded"] boolValue];

        self.assetId = [[decoder decodeObjectForKey:@"assetId"] intValue];
        self.asset = [decoder decodeObjectForKey: @"asset"];

        self.token = [decoder decodeObjectForKey: @"token"];
        
        self.isDapps = [[decoder decodeObjectForKey: @"isDapps"] boolValue];
        
        self.minConfirmations = [decoder decodeObjectForKey: @"minConfirmations"];
        self.minConfirmationsProgress = [decoder decodeObjectForKey: @"minConfirmationsProgress"];
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
            [f setDateFormat:@"yyyy MMMM dd  |  hh:mm a"];
        }
        else{
            [f setDateFormat:@"yyyy MMMM dd  |  HH:mm"];
        }
    }
    else{
        if ([[NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]] rangeOfString:@"a"].location!=NSNotFound) {
            [f setDateFormat:@"dd MMMM yyyy  |  hh:mm a"];
        }
        else{
            [f setDateFormat:@"dd MMMM yyyy  |  HH:mm"];
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
    return [self.status isEqualToString:[[@"canceled" localized] lowercaseString]];
}

-(BOOL)hasPaymentProof {
    return (self.isIncome == NO && self.enumStatus == BMTransactionStatusCompleted && self.isSelf == NO && self.isDapps == NO);
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
    
    NSString *assetName = [[AssetsManager sharedManager] getAsset:_assetId].unitName;

    NSString *detail = [NSString stringWithFormat:@"Sender: %@\nReceiver: %@\nAmount: %@ %@\nKernel ID: %@", _senderAddress, _receiverAddress, number, assetName, _kernelId];
    detail = [detail stringByReplacingOccurrencesOfString:@"  " withString:@" "];
    return detail;
}

-(NSString*)csvLine {
    NSString *csvText = @"Type,Date | Time,\"Amount, BEAM\",\"Amount USD\",\"Amount BTC\",\"Transaction fee, BEAM\",Status,Address type,Transaction ID,Kernel ID,Sending address,Sending identity,Receiving address,Receiving identity,Token,Payment proof";

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
    NSString *_secondAmountUSD = [[ExchangeManager sharedManager] exchangeValue:_realAmount to:BMCurrencyUSD];
    NSString *_secondAmountBTC = [[ExchangeManager sharedManager] exchangeValue:_realAmount to:BMCurrencyBTC];

    NSString *_status = self.status;
    NSString *_sAddress = self.senderAddress;
    NSString *_sIdenitty = self.senderIdentity;
    NSString *_rAddress = self.receiverAddress;
    NSString *_rIdentity = self.receiverIdentity;
    NSString *_addresstype = [self getAddressType];
    NSString *_proof = @"";

    NSString *_fee =  [[formatter stringFromNumber:[NSNumber numberWithDouble:self.fee]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *_id = self.ID;
    NSString *_kernel = self.kernelId;
    NSString *_tkn = self.token;
    if(_tkn == nil) {
        _tkn = @"";
    }
    
    NSArray *array = @[_type, _date, _amount, _secondAmountUSD, _secondAmountBTC ,_fee, _status, _addresstype, _id, _kernel ,_sAddress, _sIdenitty, _rAddress, _rIdentity, _tkn, _proof];
    
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

-(NSString*)statusType {
    NSString *statusValue = @"";
    
    if (_isPublicOffline) {
        statusValue =  [NSString stringWithFormat:@"%@ (%@ %@)", _status, [[@"public" localized]lowercaseString], [[@"offline" localized]lowercaseString]];
    }
    else if (_isMaxPrivacy) {
        statusValue = [NSString stringWithFormat:@"%@ (%@)", _status, [[@"maximum_anonymity" localized]lowercaseString]];
    }
    else if (_isShielded || _enumType == BMTransactionTypePushTransaction){
        statusValue = [NSString stringWithFormat:@"%@ (%@)", _status, [[@"offline" localized]lowercaseString]];
    }
    else {
        statusValue = _status;
    }
    
    if (self.enumStatus == BMTransactionStatusConfirming) {
        statusValue = [NSString stringWithFormat:@"%@ (%@)", statusValue, _minConfirmationsProgress];
    }
    
    return statusValue;
}

-(NSString*_Nonnull)source {
    if (_isIncome) {
        if (!_isDapps) {
            return _receiverAddress;
        }
        else {
            if (_appName != nil) {
                return _appName;
            }
        }
    }
    else {
        if (!_isDapps) {
            return _senderAddress;
        }
        else {
            if (_appName != nil) {
                return _appName;
            }
        }
    }
    return @"";
}

-(NSString*)getAddressType {
    if (_isPublicOffline) {
        return [@"public_offline" localized];
    }
    else if (_isMaxPrivacy) {
        return [@"max_privacy" localized];
    }
    else if (_isShielded || _enumType == BMTransactionTypePushTransaction){
        return [@"offline" localized];
    }
    return [@"regular" localized];
}

-(NSString*)amountString {
    NSString *number = [[StringManager sharedManager] realAmountStringAsset:_asset value:_realAmount];

    if (_isIncome) {
        return [NSString stringWithFormat:@"+%@", number];
    }
    else {
        return [NSString stringWithFormat:@"-%@", number];
    }
}

-(NSString*)statusName {
    NSString *status = @"";
    
    if(_isIncome) {
       status = [@"receive" localized];
    }
    else {
        status = [@"send" localized];
    }
    
    return status;
}

-(UIImage*)statusIcon {
    if (self.enumType == BMTransactionTypePushTransaction) {
        if(_isIncome) {
            if (_isSelf && !self.isFailed) {
                switch (_enumStatus) {
                    case BMTransactionStatusCompleted:
                        return !_isShielded ? [UIImage imageNamed:@"icon-sent-max-privacy-own"] : [UIImage imageNamed:@"icon-sent-own-offline"];
                    case BMTransactionStatusConfirming:
                        return !_isShielded ? [UIImage imageNamed:@"icon-sent-max-privacy-own"] : [UIImage imageNamed:@"icon-sent-own-offline"];
                    default:
                        return !_isShielded ? [UIImage imageNamed:@"icon-seding-max-privacy-own"] : [UIImage imageNamed:@"icon-send-own-offline"];
                }
            }
            else if(self.isCancelled) {
                return _isShielded ? [UIImage imageNamed:@"icon-canceled-max-offline"] : [UIImage imageNamed:@"icon-canceled-max-online"];
            }
            else if(self.isFailed) {
                return _isShielded ? [UIImage imageNamed:@"icon-failed-max-offline"] : [UIImage imageNamed:@"icon-failed-max-online"];
            }
            else if (_isPublicOffline || _isMaxPrivacy) {
                switch (_enumStatus) {
                    case BMTransactionStatusConfirming:
                        return [UIImage imageNamed:@"icon-received-max-privacy-online"];
                    case BMTransactionStatusCompleted:
                        return [UIImage imageNamed:@"icon-received-max-privacy-online"];
                    default:
                        return [UIImage imageNamed:@"icon-in-progress-receive-max-privacy-online"];
                }
            }
            else {
                switch (_enumStatus) {
                    case BMTransactionStatusPending:
                        return _isShielded ? [UIImage imageNamed:@"icon-in-progress-receive-max-privacy-offline"] : [UIImage imageNamed:@"icon-in-progress-receive-max-privacy-online"];
                    case BMTransactionStatusInProgress:
                        return _isShielded ? [UIImage imageNamed:@"icon-in-progress-receive-max-privacy-offline"] : [UIImage imageNamed:@"icon-in-progress-receive-max-privacy-online"];
                    case BMTransactionStatusRegistering:
                        return _isShielded ? [UIImage imageNamed:@"icon-in-progress-receive-max-privacy-offline"] : [UIImage imageNamed:@"icon-in-progress-receive-max-privacy-online"];
                    case BMTransactionStatusCompleted:
                        return [UIImage imageNamed:@"icon-received-max-privacy-offline"];
                    case BMTransactionStatusConfirming:
                        return [UIImage imageNamed:@"icon-received-max-privacy-offline"];
                    default:
                        return _isShielded ? [UIImage imageNamed:@"icon-in-progress-receive-max-privacy-offline"] : [UIImage imageNamed:@"icon-in-progress-receive-max-privacy-online"];
                }
            }
        }
        else{
            if (_isSelf && !self.isFailed) {
                switch (_enumStatus) {
                    case BMTransactionStatusCompleted:
                        return !_isShielded ? [UIImage imageNamed:@"icon-sent-max-privacy-own"] : [UIImage imageNamed:@"icon-sent-own-offline"];
                    case BMTransactionStatusConfirming:
                        return !_isShielded ? [UIImage imageNamed:@"icon-sent-max-privacy-own"] : [UIImage imageNamed:@"icon-sent-own-offline"];
                    default:
                        return !_isShielded ? [UIImage imageNamed:@"icon-seding-max-privacy-own"] : [UIImage imageNamed:@"icon-send-own-offline"];
                }
            }
            else if(self.isCancelled) {
                if (_isPublicOffline || _isMaxPrivacy) {
                    return [UIImage imageNamed:@"icon-canceled-max-online"];
                }
                else {
                    return _isShielded ? [UIImage imageNamed:@"icon-canceled-max-offline"] : [UIImage imageNamed:@"icon-canceled-max-online"];
                }
            }
            else if(self.isFailed) {
                if (_isPublicOffline || _isMaxPrivacy) {
                    return [UIImage imageNamed:@"icon-failed-max-online"];
                }
                else {
                    return _isShielded ? [UIImage imageNamed:@"icon-failed-max-offline"] : [UIImage imageNamed:@"icon-failed-max-online"];
                }
            }
            else if (_isPublicOffline || _isMaxPrivacy) {
                switch (_enumStatus) {
                    case BMTransactionStatusPending:
                        return [UIImage imageNamed:@"icon-in-progress-max-online"];
                    case BMTransactionStatusInProgress:
                        return [UIImage imageNamed:@"icon-in-progress-max-online"];
                    case BMTransactionStatusRegistering:
                        return [UIImage imageNamed:@"icon-in-progress-max-online"];
                    case BMTransactionStatusCompleted:
                        return [UIImage imageNamed:@"icon-send-max-online"];
                    case BMTransactionStatusConfirming:
                        return [UIImage imageNamed:@"icon-send-max-online"];
                    default:
                        return _isShielded ? [UIImage imageNamed:@"icon-in-progress-max-offline"] : [UIImage imageNamed:@"icon-in-progress-max-online"];
                }
            }
            else {
                switch (_enumStatus) {
                    case BMTransactionStatusPending:
                        return _isShielded ? [UIImage imageNamed:@"icon-in-progress-max-offline"] : [UIImage imageNamed:@"icon-in-progress-max-online"];
                    case BMTransactionStatusInProgress:
                        return _isShielded ? [UIImage imageNamed:@"icon-in-progress-max-offline"] : [UIImage imageNamed:@"icon-in-progress-max-online"];
                    case BMTransactionStatusRegistering:
                        return _isShielded ? [UIImage imageNamed:@"icon-in-progress-max-offline"] : [UIImage imageNamed:@"icon-in-progress-max-online"];
                    case BMTransactionStatusCompleted:
                        return _isShielded ? [UIImage imageNamed:@"icon-send-max-offline"] : [UIImage imageNamed:@"icon-send-max-online"];
                    case BMTransactionStatusConfirming:
                        return _isShielded ? [UIImage imageNamed:@"icon-send-max-offline"] : [UIImage imageNamed:@"icon-send-max-online"];
                    default:
                        return _isShielded ? [UIImage imageNamed:@"icon-in-progress-max-offline"] : [UIImage imageNamed:@"icon-in-progress-max-online"];
                }
            }
        }
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
    else if (self.isFailed && !self.isExpired && !self.isCancelled)
    {
        if (_isIncome) {
            return [UIImage imageNamed:@"icon-received-failed"];
        }
        else {
            return [UIImage imageNamed:@"icon-send-failed"];
        }
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
            case BMTransactionStatusConfirming:
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
            case BMTransactionStatusConfirming:
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
            case BMTransactionStatusConfirming:
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
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#ffffff"] range:NSMakeRange(0, string.string.length)];
        [string addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"SFProDisplay-Regular" size:fontsize] range:NSMakeRange(0, string.string.length)];
        
        if (commentRange.location!=NSNotFound) {
            [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#0bccf7"] range:NSMakeRange(commentRange.location+1, commentRange.length)];
        }
        
        NSMutableAttributedString *commentString = [[NSMutableAttributedString alloc] init];
        [commentString appendAttributedString:[NSMutableAttributedString attributedStringWithAttachment:attach]];
        [commentString appendAttributedString:[[NSAttributedString alloc]initWithString:@"   "]];
        [commentString appendAttributedString:string];
        
        [strings addObject:commentString];
    }
    
    if (idRange.location!=NSNotFound) {
        NSString *localizable = [[@"transaction_id" localized] uppercaseString];
        
        NSMutableAttributedString *localizableString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", localizable]];
        [localizableString addAttribute:NSForegroundColorAttributeName value:[[UIColor colorWithHexString:@"#ffffff"]colorWithAlphaComponent:0.5] range:NSMakeRange(0, localizableString.string.length)];
        [localizableString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, localizableString.string.length)];
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",_ID]];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#ffffff"] range:NSMakeRange(0, string.string.length)];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#0bccf7"] range:[string.string.lowercaseString rangeOfString:searchText.lowercaseString]];
        
        NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
        [result appendAttributedString:localizableString];
        [result appendAttributedString:string];
        
        [strings addObject:result];
    }
    
    if (kernelRange.location!=NSNotFound) {
        NSString *localizable = [[@"kernel_id" localized] uppercaseString];
        
        NSMutableAttributedString *localizableString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", localizable]];
        [localizableString addAttribute:NSForegroundColorAttributeName value:[[UIColor colorWithHexString:@"#ffffff"]colorWithAlphaComponent:0.5] range:NSMakeRange(0, localizableString.string.length)];
        [localizableString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, localizableString.string.length)];
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",_kernelId]];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#ffffff"] range:NSMakeRange(0, string.string.length)];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#0bccf7"] range:[string.string.lowercaseString rangeOfString:searchText.lowercaseString]];
        
        NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
        [result appendAttributedString:localizableString];
        [result appendAttributedString:string];
        
        [strings addObject:result];
    }
    
    if (senderAddressRange.location!=NSNotFound) {
        NSString *localizable = [[@"sending_address" localized] uppercaseString];
        
        NSMutableAttributedString *localizableString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", localizable]];
        [localizableString addAttribute:NSForegroundColorAttributeName value:[[UIColor colorWithHexString:@"#ffffff"]colorWithAlphaComponent:0.5] range:NSMakeRange(0, localizableString.string.length)];
        [localizableString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, localizableString.string.length)];
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",_senderAddress]];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#ffffff"] range:NSMakeRange(0, string.string.length)];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#0bccf7"] range:[string.string.lowercaseString rangeOfString:searchText.lowercaseString]];
        
        NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
        [result appendAttributedString:localizableString];
        [result appendAttributedString:string];
        
        [strings addObject:result];
    }
    
    if (receiverAddressRange.location!=NSNotFound) {
        NSString *localizable = [[@"receiving_address" localized] uppercaseString];
        
        NSMutableAttributedString *localizableString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", localizable]];
        
        [localizableString addAttribute:NSForegroundColorAttributeName value:[[UIColor colorWithHexString:@"#ffffff"]colorWithAlphaComponent:0.5] range:NSMakeRange(0, localizableString.string.length)];
        [localizableString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, localizableString.string.length)];
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",_receiverAddress]];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#ffffff"] range:NSMakeRange(0, string.string.length)];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#0bccf7"] range:[string.string.lowercaseString rangeOfString:searchText.lowercaseString]];
        
        NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
        [result appendAttributedString:localizableString];
        [result appendAttributedString:string];
        
        [strings addObject:result];
    }
    
    if (senderNameRange.location!=NSNotFound) {
        NSString *localizable = [[@"sending_address" localized] uppercaseString];
        
        NSMutableAttributedString *localizableString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", localizable]];
        [localizableString addAttribute:NSForegroundColorAttributeName value:[[UIColor colorWithHexString:@"#ffffff"]colorWithAlphaComponent:0.5] range:NSMakeRange(0, localizableString.string.length)];
        [localizableString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, localizableString.string.length)];
        
        NSMutableAttributedString *addressString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",_senderAddress]];
        [addressString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#ffffff"] range:NSMakeRange(0, addressString.string.length)];
        [addressString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#0bccf7"] range:[addressString.string.lowercaseString rangeOfString:searchText.lowercaseString]];
        
        NSTextAttachment *attach = [[NSTextAttachment alloc] init];
        attach.image = [UIImage imageNamed:@"iconContact"];
        attach.bounds = CGRectMake(0, -3, 16, 16);
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",_senderContactName]];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#ffffff"] range:NSMakeRange(0, string.string.length)];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#0bccf7"] range:senderNameRange];
        [string addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, string.string.length)];
        
        NSMutableAttributedString *commentString = [[NSMutableAttributedString alloc] init];
        [commentString appendAttributedString:[NSMutableAttributedString attributedStringWithAttachment:attach]];
        [commentString appendAttributedString:[[NSAttributedString alloc]initWithString:@"    "]];
        [commentString appendAttributedString:string];
        
        
        [strings addObject:localizableString];
        [strings addObject:commentString];
        [strings addObject:addressString];
    }
    
    if (receiverNameRange.location!=NSNotFound) {
        NSString *localizable = [[@"receiving_address" localized] uppercaseString];
        
        NSMutableAttributedString *localizableString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", localizable]];
        [localizableString addAttribute:NSForegroundColorAttributeName value:[[UIColor colorWithHexString:@"#ffffff"]colorWithAlphaComponent:0.5] range:NSMakeRange(0, localizableString.string.length)];
        [localizableString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, localizableString.string.length)];
        
        NSMutableAttributedString *addressString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",_receiverAddress]];
        [addressString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#ffffff"] range:NSMakeRange(0, addressString.string.length)];
        [addressString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#0bccf7"] range:[addressString.string.lowercaseString rangeOfString:searchText.lowercaseString]];
        
        NSTextAttachment *attach = [[NSTextAttachment alloc] init];
        attach.image = [UIImage imageNamed:@"iconContact"];
        attach.bounds = CGRectMake(0, -3, 16, 16);
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",_receiverContactName]];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#ffffff"] range:NSMakeRange(0, string.string.length)];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#0bccf7"] range:receiverNameRange];
        [string addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, string.string.length)];
        
        NSMutableAttributedString *commentString = [[NSMutableAttributedString alloc] init];
        [commentString appendAttributedString:[NSMutableAttributedString attributedStringWithAttachment:attach]];
        [commentString appendAttributedString:[[NSAttributedString alloc]initWithString:@"    "]];
        [commentString appendAttributedString:string];
        
        [strings addObject:localizableString];
        [strings addObject:commentString];
        [strings addObject:addressString];
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
    
    NSString *number = [[StringManager sharedManager] realAmountString:_realAmount];
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
        if (self.isShielded || self.isMaxPrivacy || self.isPublicOffline) {
            sender = [NSString stringWithFormat:@"%@\n%@",[[@"sender_identity" localized]uppercaseString], _senderIdentity];
        }
        else {
            sender = [NSString stringWithFormat:@"%@\n%@",[[@"contact" localized]uppercaseString], _senderAddress];
        }
        receiver = [NSString stringWithFormat:@"%@\n%@",[[@"my_address" localized]uppercaseString], _receiverAddress];
    }
    else{
        sender = [NSString stringWithFormat:@"%@\n%@",[[@"contact" localized]uppercaseString], _receiverAddress];
        receiver = [NSString stringWithFormat:@"%@\n%@",[[@"my_address" localized]uppercaseString], _senderAddress];
    }
    
    NSString *fee = [NSString stringWithFormat:@"%@\n%@",[[@"transaction_fee" localized]uppercaseString], [NSString stringWithFormat:@"%llu GROTH",_realFee]];
    
    NSString *addressType = [NSString stringWithFormat:@"%@\n%@",[[@"address_type" localized]uppercaseString], [self getAddressType]];
    
    NSString *trid = [NSString stringWithFormat:@"%@\n%@",[[@"transaction_id" localized]uppercaseString], _ID];
    
    [details addObject:date];
    [details addObject:status];
    [details addObject:amount];
    [details addObject:sender];
    [details addObject:receiver];
    if (_realFee > 0) {
        [details addObject:fee];
    }
    [details addObject:addressType];
    [details addObject:trid];
    
    if(_identity.length > 0){
        NSString *identity = [NSString stringWithFormat:@"%@\n%@",[[@"wallet_id" localized]uppercaseString], _identity];
        [details addObject:identity];
    }
    
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

