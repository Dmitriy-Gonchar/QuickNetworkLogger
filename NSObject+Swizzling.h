//
//  NSObject+Swizzling.h
//
//  Created by Jesus++ on 09.01.2021.
//

#import <Foundation/Foundation.h>

#define let __auto_type const
#define var __auto_type

@interface NSObject (Swizzling)

+ (BOOL)gl_swizzleMethod: (SEL)origSel withMethod: (SEL)altSel;
+ (BOOL)gl_swizzleClassMethod: (SEL)origSel withMethod: (SEL)altSel;

@end
