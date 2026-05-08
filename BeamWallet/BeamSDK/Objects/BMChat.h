//
//  BMChat.h
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

#import <Foundation/Foundation.h>

@interface BMChat : NSObject

@property (nonatomic, strong) NSString * _Nonnull peerWalletId;
@property (nonatomic, strong) NSString * _Nullable contactName;
@property (nonatomic, strong) NSString * _Nullable myWalletId;
@property (nonatomic, assign) BOOL hasUnread;
@property (nonatomic, strong) NSString * _Nullable lastMessagePreview;
@property (nonatomic, assign) UInt64 lastMessageTimestamp;

-(NSString * _Nonnull)displayName;

@end
