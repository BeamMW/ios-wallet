//
// StringLocalize.m
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

#import "StringLocalize.h"
#import "AppModel.h"

@implementation NSString (Localization)

-(NSString*)localized {
    NSString *result = @"";
    
    NSString *lang = [Settings sharedManager].language;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *remotePath = [[documentsDirectory stringByAppendingPathComponent:@"localization"] stringByAppendingPathComponent:lang];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:remotePath]) {
        NSBundle *bundle = [NSBundle bundleWithPath:remotePath];
        
        if (bundle!=nil) {
            result =  NSLocalizedStringWithDefaultValue(self, nil, bundle, @"", @"");
        }
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:lang ofType:@"lproj"];
    NSBundle * bundle = [[NSBundle alloc] initWithPath:path];
    
    result =  NSLocalizedStringWithDefaultValue(self, nil, bundle, @"", @"");
    
    if ([result isEqualToString:self]) {
        NSString *pathEn = [[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"];
        NSBundle * bundleEn = [[NSBundle alloc] initWithPath:pathEn];
        result =  NSLocalizedStringWithDefaultValue(self, nil, bundleEn, @"", @"");
    }
    
    return result;
}

@end
