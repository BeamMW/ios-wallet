//
// RecoveryProgress.m
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

#import "RecoveryProgress.h"
#import "AppModel.h"

RecoveryProgress::RecoveryProgress()
{
    
}

RecoveryProgress::~RecoveryProgress()
{
    
}

bool RecoveryProgress::OnProgress(uint64_t done, uint64_t total) {    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onSyncProgressUpdated: total:)]) {
            [delegate onSyncProgressUpdated:(int)done total:(int)total];
        }
    }
    return [AppModel sharedManager].isRestoreFlow;
}

