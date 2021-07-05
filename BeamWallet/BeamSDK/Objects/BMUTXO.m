//
//  BMUTXO.m
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

#import "BMUTXO.h"
#import "BMTransaction.h"
#import "StringLocalize.h"
#import "Settings.h"
#import "StringManager.h"
#import "AssetsManager.h"

@implementation BMUTXO

-(NSMutableAttributedString*_Nonnull)attributedStatus {
    if(_status == BMUTXOMaturing) {
        NSString *available = [NSString stringWithFormat:@"(%@ %llu)",[@"till_block" localized].lowercaseString, self.maturity];
        NSString *str = [NSString stringWithFormat:@"%@ %@",self.statusString.lowercaseString, available];
        
        NSRange range = [str rangeOfString:available];
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:str];
        [attrString addAttribute:NSForegroundColorAttributeName value:[Settings sharedManager].isDarkMode ?  [UIColor colorWithRed:142.0f/255.0f green:142.0f/255.0f blue:147.0f/255.0f alpha:1] : [UIColor lightGrayColor] range:range];
        return attrString;
    }
    else if(_maturity > 0) {
        NSString *available = [NSString stringWithFormat:@"(%@ %llu %@)",[@"since" localized].lowercaseString, self.maturity, [@"block_height" localized].lowercaseString];
        NSString *str = [NSString stringWithFormat:@"%@ %@",self.statusString.lowercaseString, available];
        
        NSRange range = [str rangeOfString:available];
        
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:str];
        [attrString addAttribute:NSForegroundColorAttributeName value:[Settings sharedManager].isDarkMode ?  [UIColor colorWithRed:142.0f/255.0f green:142.0f/255.0f blue:147.0f/255.0f alpha:1] : [UIColor lightGrayColor] range:range];
        return attrString;
    }
    else{
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:_statusString];
        return attrString;
    }
}

-(NSString*_Nonnull)amountString {
    NSString *number = @"";
    BMAsset *asset = [[AssetsManager sharedManager] getAsset:_assetId];
    if (asset != nil) {
        number = [[StringManager sharedManager] realAmountStringAsset:asset value:_realAmount];
    }
    else {
        number = [NSString stringWithFormat:@"%f", _realAmount];
    }
    
    return number;
}

@end
