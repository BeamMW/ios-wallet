//
//  MFMailComposeViewControllerRecipient.m
//  BeamWallet
//
//  Created by Denis on 3/14/19.
//  Copyright © 2019 Denis. All rights reserved.
//

#import "MFMailComposeViewControllerRecipient.h"
#import <objc/message.h>

@implementation MFMailComposeViewController (Recipient)

+ (void)load {
    MethodSwizzle(self, @selector(setMessageBody:isHTML:), @selector(setMessageBodySwizzled:isHTML:));
}



static void MethodSwizzle(Class c, SEL origSEL, SEL overrideSEL)
{
    Method origMethod = class_getInstanceMethod(c, origSEL);
    Method overrideMethod = class_getInstanceMethod(c, overrideSEL);
    
    if (class_addMethod(c, origSEL, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod))) {
        class_replaceMethod(c, overrideSEL, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, overrideMethod);
    }
}

- (void)setMessageBodySwizzled:(NSString*)body isHTML:(BOOL)isHTML
{
    NSArray * recipients = @[@"support@beam.mw"];
    [self setToRecipients:recipients];
    
    [self setMessageBodySwizzled:body isHTML:isHTML];
}

@end
