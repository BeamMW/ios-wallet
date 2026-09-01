//
//  WalletAPIClient+Internal.h
//  BeamWallet
//
//  C++-only init for WalletAPIClient. Keep this out of the bridging header —
//  it pulls in WalletModel which transitively requires C++ standard headers.
//  Import this only from Objective-C++ translation units.
//

#import "WalletAPIClient.h"
#import "WalletModel.h"

@interface WalletAPIClient ()

- (instancetype _Nonnull)initWithWallet:(WalletModel::Ptr)wallet;

@end
