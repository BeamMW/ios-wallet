//
//  BMInstalledDApp.m
//  BeamWallet
//

#import "BMInstalledDApp.h"

@interface BMInstalledDApp ()
+ (NSString *)stringFromDictionary:(NSDictionary *)dict key:(NSString *)key defaultValue:(NSString *)def;
@end

@implementation BMInstalledDApp

- (instancetype)init {
    self = [super init];
    if (self) {
        _guid = @"";
        _name = @"";
        _desc = @"";
        _version = @"1.0";
        _localPath = @"";
        _icon = @"";
        _url = @"app/index.html";
    }
    return self;
}

- (NSDictionary<NSString *, NSString *> *)toDictionary {
    return @{
        @"guid": _guid ?: @"",
        @"name": _name ?: @"",
        @"description": _desc ?: @"",
        @"version": _version ?: @"1.0",
        @"localPath": _localPath ?: @"",
        @"icon": _icon ?: @"",
        @"url": _url ?: @"app/index.html",
    };
}

+ (instancetype)fromDictionary:(NSDictionary *)dict {
    BMInstalledDApp *d = [[BMInstalledDApp alloc] init];
    d.guid      = [self stringFromDictionary:dict key:@"guid"        defaultValue:@""];
    d.name      = [self stringFromDictionary:dict key:@"name"        defaultValue:@""];
    d.desc      = [self stringFromDictionary:dict key:@"description" defaultValue:@""];
    d.version   = [self stringFromDictionary:dict key:@"version"     defaultValue:@"1.0"];
    d.localPath = [self stringFromDictionary:dict key:@"localPath"   defaultValue:@""];
    d.icon      = [self stringFromDictionary:dict key:@"icon"        defaultValue:@""];
    d.url       = [self stringFromDictionary:dict key:@"url"         defaultValue:@"app/index.html"];
    return d;
}

+ (NSString *)stringFromDictionary:(NSDictionary *)dict key:(NSString *)key defaultValue:(NSString *)def {
    id value = dict[key];
    if ([value isKindOfClass:[NSString class]]) return value;
    if (value == nil || value == [NSNull null]) return def;
    return [NSString stringWithFormat:@"%@", value];
}

@end
