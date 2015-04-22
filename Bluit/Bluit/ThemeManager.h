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

+ (NSString *) stringForKey:(NSString *)key;
+ (UIColor *) colorForKey:(NSString *)key;

+ (NSString *) darkOrLight;

+ (UIStatusBarStyle) statusBarStyle;
+ (UIBarStyle) uiBarStyle;

+ (UIColor *) backgroundColor;
+ (UIColor *) contentBackgroundColor;

+ (UIColor *) textColor;
+ (UIColor *) secondaryTextColor;
+ (UIColor *) smallcapsHeaderColor;

+ (UIColor *) tintColor;
+ (UIColor *) inactiveColor;
+ (UIColor *) downvoteColor;
+ (UIColor *) saveColor;
+ (UIColor *) stickyColor;

+ (UIColor *) separatorColor;
+ (UIColor *) shadowColor;
+ (UIColor *) shadowBorderColor;
+ (UIColor *) shadeColor;

@end
