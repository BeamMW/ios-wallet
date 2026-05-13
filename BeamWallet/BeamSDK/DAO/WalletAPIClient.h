//
//  WalletAPIClient.h
//  BeamWallet
//
//  Wallet-owned AppsApiUI bridge used by the DApp Store browser, publishers list,
//  and IPFS / contract calls made from native UI (not from a running DApp WebView).
//  Call IDs start at WALLET_API_BASE_CALL_ID (1_000_000) so that responses for
//  these requests don't collide with the per-DApp IDs handled by DAOViewController.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern const NSInteger WalletAPIClientBaseCallID;

typedef void (^WalletAPICompletion)(NSDictionary * _Nonnull result);

@interface WalletAPIClient : NSObject

/// Lazily creates the AppsApiUI on the wallet thread. Safe to call repeatedly.
- (void)ensureApi;

/// Tear down the underlying AppsApiUI and clear pending callbacks.
- (void)destroy;

/// Encode `{jsonrpc:"2.0", id, method, params}` and dispatch to the wallet API.
/// `completion` is invoked once on the main queue with the parsed result map or
/// `{"error": ...}` on failure.
- (NSInteger)callMethod:(NSString *)method
                 params:(NSDictionary *)params
             completion:(nullable WalletAPICompletion)completion
    NS_SWIFT_NAME(call(method:params:completion:));

/// Inspect a JSON response from the C++ API. If its `id` belongs to this client
/// (`>= WalletAPIClientBaseCallID`), invokes the matching callback and returns YES.
/// Otherwise returns NO so the caller can forward the response elsewhere.
- (BOOL)routeResult:(NSString *)json;

@end

NS_ASSUME_NONNULL_END
