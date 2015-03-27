//
//  ThemeManager.h
//  redditPad
//
//  Created by Tom Graham on 26/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIApplication.h>

@class UIColor;

static NSString * const defaultTheme = @"lightTheme";
static NSString * const darkTheme = @"darkTheme";

@interface ThemeManager : NSObject

@property (strong, nonatomic) NSDictionary *theme;

+ (ThemeManager *)sharedManager;

+ (UIColor *) colorForKey:(NSString *)key;

+ (UIStatusBarStyle) statusBarStyle;

+ (UIColor *) backgroundColor;

+ (UIColor *) textColor;
+ (UIColor *) secondaryTextColor;
+ (UIColor *) contentBackgroundColor;

+ (UIColor *) tintColor;

+ (UIColor *) separatorColor;
+ (UIColor *) shadowColor;

@end
