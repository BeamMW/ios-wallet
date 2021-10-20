//
//  BMApp.h
//  BeamWallet
//
//  Created by Denis on 01.09.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BMApp : NSObject

@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *desc;
@property (nonatomic,strong) NSString *url;
@property (nonatomic,strong) NSString *icon;
@property (nonatomic,strong) NSString *api_version;
@property (nonatomic,strong) NSString *min_api_version;
@property (nonatomic,assign) BOOL isSupported;



-(void)setAPIResult:(NSDictionary*)dct;

@end

