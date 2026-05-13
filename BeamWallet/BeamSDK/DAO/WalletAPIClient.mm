//
//  WalletAPIClient.mm
//  BeamWallet
//

#import "WalletAPIClient+Internal.h"
#import "WebAPICreator.h"
#import "AppsApiUI.h"
#import "Public.h"
#import "StringStd.h"

#include "wallet/api/i_wallet_api.h"
#include "utility/logger.h"

const NSInteger WalletAPIClientBaseCallID = 1000000;

static NSString *const kWalletAPIClientAppName = @"Beam-Wallet";

@implementation WalletAPIClient {
    WebAPICreator _creator;
    NSInteger _counter;
    NSMutableDictionary<NSNumber *, WalletAPICompletion> *_callbacks;
    dispatch_queue_t _callbacksQueue;
    BOOL _apiCreationRequested;
}

- (instancetype)initWithWallet:(WalletModel::Ptr)wallet {
    self = [super init];
    if (self) {
        _creator = WebAPICreator();
        _creator._walletModel = wallet;
        _counter = WalletAPIClientBaseCallID;
        _callbacks = [NSMutableDictionary dictionary];
        _callbacksQueue = dispatch_queue_create("com.beam.WalletAPIClient.callbacks", DISPATCH_QUEUE_SERIAL);
        _apiCreationRequested = NO;
    }
    return self;
}

- (void)dealloc {
    _creator.destroyApi();
    _creator._walletModel.reset();
}

- (void)ensureApi {
    if (_apiCreationRequested) {
        return;
    }
    _apiCreationRequested = YES;
    try {
        _creator.createApi("current", "", kWalletAPIClientAppName.string, "");
    } catch (NSException *ex) {
        NSLog(@"WalletAPIClient.ensureApi: %@", ex);
        _apiCreationRequested = NO;
    }
}

- (void)destroy {
    _creator.destroyApi();
    _apiCreationRequested = NO;
    dispatch_sync(_callbacksQueue, ^{
        [_callbacks removeAllObjects];
    });
}

- (NSInteger)callMethod:(NSString *)method
                 params:(NSDictionary *)params
             completion:(WalletAPICompletion)completion {
    [self ensureApi];

    NSInteger callId = ++_counter;

    if (completion) {
        dispatch_sync(_callbacksQueue, ^{
            _callbacks[@(callId)] = [completion copy];
        });
    }

    NSDictionary *payload = @{
        @"jsonrpc": @"2.0",
        @"id": @(callId),
        @"method": method,
        @"params": params ?: @{},
    };

    NSError *err = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&err];
    if (!data) {
        [self resolveCallId:callId withResult:@{@"error": @{@"message": err.localizedDescription ?: @"JSON encode failed"}}];
        return callId;
    }
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    if (_creator._api == nil) {
        // API not yet created; report error so caller can retry later.
        [self resolveCallId:callId withResult:@{@"error": @{@"message": @"Wallet API not ready"}}];
        return callId;
    }

    try {
        _creator._api->callWalletApi(jsonString.string);
    } catch (...) {
        [self resolveCallId:callId withResult:@{@"error": @{@"message": @"callWalletApi threw"}}];
    }
    return callId;
}

- (BOOL)routeResult:(NSString *)json {
    if (json.length == 0) return NO;

    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return NO;
    NSError *err = nil;
    id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if (![parsed isKindOfClass:[NSDictionary class]]) return NO;
    NSDictionary *dict = parsed;
    id rawId = dict[@"id"];
    if (![rawId isKindOfClass:[NSNumber class]]) return NO;
    NSInteger callId = [rawId integerValue];
    if (callId < WalletAPIClientBaseCallID) return NO;

    NSDictionary *result = [self parseAnswer:dict];
    [self resolveCallId:callId withResult:result];
    return YES;
}

- (NSDictionary *)parseAnswer:(NSDictionary *)answer {
    if (answer[@"error"] != nil) {
        id err = answer[@"error"];
        if ([err isKindOfClass:[NSDictionary class]]) {
            return @{@"error": err};
        } else if ([err isKindOfClass:[NSString class]]) {
            return @{@"error": @{@"message": err}};
        }
        return @{@"error": @{@"message": @"Unknown error"}};
    }

    id rawResult = answer[@"result"];
    if ([rawResult isKindOfClass:[NSDictionary class]]) {
        NSDictionary *resDict = rawResult;
        // Shader invoke_contract responses carry their payload as a JSON string in "output".
        NSString *output = resDict[@"output"];
        if ([output isKindOfClass:[NSString class]]) {
            NSData *outData = [output dataUsingEncoding:NSUTF8StringEncoding];
            NSError *outErr = nil;
            id outParsed = outData ? [NSJSONSerialization JSONObjectWithData:outData options:0 error:&outErr] : nil;
            if ([outParsed isKindOfClass:[NSDictionary class]]) {
                NSDictionary *outDict = outParsed;
                if (outDict[@"error"] != nil) {
                    return @{@"error": outDict[@"error"]};
                }
                NSMutableDictionary *merged = [outDict mutableCopy];
                if (resDict[@"raw_data"] != nil) {
                    merged[@"raw_data"] = resDict[@"raw_data"];
                }
                return merged;
            }
        }
        return resDict;
    }
    if ([rawResult isKindOfClass:[NSString class]]) {
        return @{@"address": rawResult};
    }
    if ([rawResult isKindOfClass:[NSArray class]]) {
        return @{@"messages": rawResult};
    }
    return @{};
}

- (void)resolveCallId:(NSInteger)callId withResult:(NSDictionary *)result {
    __block WalletAPICompletion cb = nil;
    dispatch_sync(_callbacksQueue, ^{
        cb = _callbacks[@(callId)];
        if (cb) {
            [_callbacks removeObjectForKey:@(callId)];
        }
    });
    if (cb) {
        dispatch_async(dispatch_get_main_queue(), ^{
            cb(result);
        });
    }
}

@end
