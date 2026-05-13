//
//  BMInstalledDApp.h
//  BeamWallet
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BMInstalledDApp : NSObject

@property (nonatomic, strong) NSString *guid;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *localPath;
@property (nonatomic, strong) NSString *icon;
@property (nonatomic, strong) NSString *url;

- (NSDictionary<NSString *, NSString *> *)toDictionary;
+ (instancetype)fromDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
