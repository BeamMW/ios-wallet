//
//  BMWalletStatus.m
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

#import "BMWalletStatus.h"

@implementation BMWalletStatus

-(id)init{
    self = [super init];
    
    _available = 0;
    _sending = 0;
    _receiving = 0;
    _maturing = 0;
    _realAmount = 0;
    _realReceiving = 0;
    _realMaturing = 0;
    _realSending = 0;

    return self;
}

-(BOOL)isSendingAndReceiving {
    return (_realSending >0 && _realReceiving > 0);
}
    
-(BOOL)hasInProgressBalance {
    return (_realSending >0 || _realReceiving > 0);
}

@end
