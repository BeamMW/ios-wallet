//
//  BMAvailableDApp.h
//  BeamWallet
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BMAvailableDApp : NSObject

@property (nonatomic, strong) NSString *guid;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *ipfsCid;
@property (nonatomic, strong) NSString *publisher;
@property (nonatomic, strong) NSString *icon;
@property (nonatomic, strong) NSString *bundledAsset;
@property (nonatomic, strong) NSString *publisherName;

@end

NS_ASSUME_NONNULL_END
