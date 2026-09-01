//
//  BMPublisher.h
//  BeamWallet
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BMPublisher : NSObject

@property (nonatomic, strong) NSString *pubkey;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *aboutMe;
@property (nonatomic, strong) NSString *website;
@property (nonatomic, strong) NSString *twitter;
@property (nonatomic, strong) NSString *linkedin;
@property (nonatomic, strong) NSString *instagram;
@property (nonatomic, strong) NSString *telegram;
@property (nonatomic, strong) NSString *discord;

@end

NS_ASSUME_NONNULL_END
