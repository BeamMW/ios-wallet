//
// MnemonicModel.m
// BeamTest
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

#import "MnemonicModel.h"
#import "StringStd.h"
#include "mnemonic/mnemonic.h"

using namespace beam;
using namespace std;

@implementation MnemonicModel

static NSMutableArray *phrases;

+(BOOL)isValidPhrase:(NSString*)phrase {
    NSArray *wordsArray = [phrase componentsSeparatedByString:@";"];
    
    vector<string> wordList(wordsArray.count);
    
    for(int i=0; i<wordsArray.count; ++i){
        NSString *word = wordsArray[i];
        wordList[i] = word.string;
    }
    
    return isValidMnemonic(wordList,language::en);
}

+(BOOL)isValidWord:(NSString*)word {
    return isAllowedWord(word.string, language::en);
}

+(NSString*)generatePhrase {
    auto wordList = createMnemonic(getEntropy(), language::en);
    
    assert(wordList.size() == 12);
    
    NSMutableArray *words = @[].mutableCopy;
    
    for (const auto& word : wordList)
    {
        NSString* result = [NSString stringWithUTF8String:word.c_str()];
        [words addObject:result];
    }
    
    return [words componentsJoinedByString:@";"];
}

+(NSArray<NSString*>*_Nonnull)mnemonicWordsForPrefix:(NSString*_Nonnull)prefix suggestions:(NSArray*_Nullable)suggestions {
    
    BOOL isFullword = NO;

    if (prefix.length == 0)
    {
        return @[];
    }
    
    if (suggestions!=nil) {
        NSMutableArray *result = [NSMutableArray array];
        
        for (NSString *phrase in suggestions) {
            if ([phrase hasPrefix:prefix]) {
                [result addObject:phrase];
            }
        }
        
        return [NSArray arrayWithArray:result];
    }
    else{
        if (phrases == nil) {
            NSString *string = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"phrases" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
            phrases = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@"\n"]];
        }
        
        NSMutableArray *result = [NSMutableArray array];
        
        for (NSString *phrase in phrases) {
            if ([phrase isEqualToString:prefix])
            {
                isFullword = YES;
                [result addObject:phrase];
            }
            else if ([phrase hasPrefix:prefix]) {
                [result addObject:phrase];
            }
        }
        
        if (isFullword)
        {
            return [NSArray arrayWithObject:prefix];
        }
        else{
            return [NSArray arrayWithArray:result];
        }
    }
}


@end
