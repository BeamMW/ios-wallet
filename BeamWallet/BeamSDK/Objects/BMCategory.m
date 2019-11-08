//
// BMCategory.m
// BeamWallet
//
// Copyright 2018 Beam Development
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "BMCategory.h"
#import "StringLocalize.h"

@implementation BMCategory

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:[NSNumber numberWithInt:self.ID] forKey: @"ID"];
    [encoder encodeObject:self.name forKey: @"name"];
    [encoder encodeObject:self.color forKey: @"color"];
}

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if(self)
    {
        self.ID = [[decoder decodeObjectForKey: @"ID"] intValue];
        self.name = [decoder decodeObjectForKey: @"name"];
        self.color = [decoder decodeObjectForKey:@"color"];
    }
    return self;
}

+(BMCategory*_Nonnull)noneCategory {
    BMCategory *category = [[BMCategory alloc] init];
    category.name = [@"none" localized];
    category.ID = 0;
    category.color = @"FFFFFF";
    return category;
}

+(BMCategory*_Nonnull)fromDict:(NSDictionary*_Nonnull)dict {
    BMCategory *category = [[BMCategory alloc] init];
    category.name = [dict objectForKey:@"name"];
    category.ID = [[dict objectForKey:@"id"] intValue];
    category.color = [dict objectForKey:@"color"];;
    return category;
}

-(NSDictionary*_Nonnull)dict {
    return @{@"id":[NSString stringWithFormat:@"%d",_ID],@"name":_name,@"color":_color};
}

@end
