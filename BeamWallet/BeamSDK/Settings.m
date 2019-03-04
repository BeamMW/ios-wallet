//
//  Settings.m
//  BeamTest
//
//  Created by Denis on 2/28/19.
//  Copyright © 2019 Denis. All rights reserved.
//

#import "Settings.h"

@implementation Settings

+(NSString*)nodeAddress {
    //TESTNET
//    "ap-node01.testnet.beam.mw:8100",
//    "ap-node02.testnet.beam.mw:8100",
//    "ap-node03.testnet.beam.mw:8100",
//    "eu-node01.testnet.beam.mw:8100",
//    "eu-node02.testnet.beam.mw:8100",
//    "eu-node03.testnet.beam.mw:8100",
//    "us-node01.testnet.beam.mw:8100",
//    "us-node02.testnet.beam.mw:8100",
//    "us-node03.testnet.beam.mw:8100"
    return @"ap-node03.testnet.beam.mw:8100";
}

+(NSString*)walletStoragePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/test_wallet"];
    return dataPath;
}

@end
