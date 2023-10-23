//
//  NSObject+Swizzling.h
//
//  Created by Jesus++ on 09.01.2021.
//

#import <Foundation/Foundation.h>

#define let __auto_type const
#define var __auto_type

@interface NSObject (Swizzling)

+ (BOOL)swizzleMethod: (SEL)origSel withMethod: (SEL)altSel;
+ (BOOL)swizzleClassMethod: (SEL)origSel withMethod: (SEL)altSel;

@end
