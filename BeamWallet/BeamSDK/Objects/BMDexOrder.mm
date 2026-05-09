//
//  BMDexOrder.mm
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

#import "BMDexOrder.h"

static NSString *FormatGroth(UInt64 amount) {
    double beam = (double)amount / 100000000.0;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 8;
    return [formatter stringFromNumber:@(beam)] ?: @"0";
}

@implementation BMDexOrder

-(instancetype)init {
    self = [super init];
    if (self) {
        _orderID = @"";
        _sbbsID = @"";
        _sendAssetSName = @"";
        _receiveAssetSName = @"";
    }
    return self;
}

-(BOOL)isExpired {
    if (self.expireTimestamp == 0) return NO;
    return self.expireTimestamp < (UInt64)[[NSDate date] timeIntervalSince1970];
}

-(BOOL)isActive {
    return !self.isExpired && !self.isCanceled && !self.isCompleted && !self.isAccepted;
}

-(NSString * _Nonnull)displayCreatedDate {
    if (self.createTimestamp == 0) return @"";
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.createTimestamp];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    return [formatter stringFromDate:date];
}

-(NSString * _Nonnull)displayExpiresIn {
    if (self.expireTimestamp == 0) return @"—";
    NSDate *expire = [NSDate dateWithTimeIntervalSince1970:self.expireTimestamp];
    NSTimeInterval delta = [expire timeIntervalSinceDate:[NSDate date]];
    if (delta <= 0) return @"expired";

    NSInteger seconds = (NSInteger)delta;
    NSInteger days = seconds / 86400;
    NSInteger hours = (seconds % 86400) / 3600;
    NSInteger minutes = (seconds % 3600) / 60;

    if (days > 0) return [NSString stringWithFormat:@"%ldd %ldh", (long)days, (long)hours];
    if (hours > 0) return [NSString stringWithFormat:@"%ldh %ldm", (long)hours, (long)minutes];
    return [NSString stringWithFormat:@"%ldm", (long)minutes];
}

-(NSString * _Nonnull)displaySendAmount {
    return [NSString stringWithFormat:@"%@ %@", FormatGroth(self.sendAmount), self.sendAssetSName];
}

-(NSString * _Nonnull)displayReceiveAmount {
    return [NSString stringWithFormat:@"%@ %@", FormatGroth(self.receiveAmount), self.receiveAssetSName];
}

-(NSString * _Nonnull)displayRate {
    if (self.sendAmount == 0) return @"—";
    double rate = (double)self.receiveAmount / (double)self.sendAmount;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.maximumFractionDigits = 8;
    formatter.minimumFractionDigits = 0;
    NSString *rateString = [formatter stringFromNumber:@(rate)] ?: @"0";
    return [NSString stringWithFormat:@"1 %@ = %@ %@", self.sendAssetSName, rateString, self.receiveAssetSName];
}

-(NSString * _Nonnull)displayStatus {
    if (self.isCompleted) return @"completed";
    if (self.isCanceled) return @"canceled";
    if (self.isAccepted) return @"accepted";
    if ([self isExpired]) return @"expired";
    return @"open";
}

@end
