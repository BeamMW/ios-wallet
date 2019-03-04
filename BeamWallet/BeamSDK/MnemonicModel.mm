//
//  MnemonicModel.m
//  BeamTest
//
//  Created by Denis on 2/28/19.
//  Copyright © 2019 Denis. All rights reserved.
//

#import "MnemonicModel.h"
#import "StringStd.h"

#include "mnemonic/mnemonic.h"

using namespace beam;
using namespace std;

@implementation MnemonicModel

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

@end
