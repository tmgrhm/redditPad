//
//  ThemeManager.h
//  redditPad
//
//  Created by Tom Graham on 26/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIApplication.h>

@class UIColor;

static NSString * const kTGThemeDefault = @"lightTheme";
static NSString * const kTGThemeDark = @"darkTheme";

static NSString * const kThemeDidChangeNotification = @"TGThemeDidChange";

static NSString * const kTGThemeBackgroundColor = @"backgroundColor";
static NSString * const kTGThemeContentBackgroundColor = @"contentBackgroundColor";
static NSString * const kTGThemeFadedBackgroundColor = @"hiddenCommentBackground";

static NSString * const kTGThemeTextColor = @"textColor";
static NSString * const kTGThemeSecondaryTextColor = @"secondaryTextColor";
static NSString * const kTGThemeSmallcapsHeaderColor = @"smallcapsHeaderColor";

static NSString * const kTGThemeTintColor = @"tintColor";
static NSString * const kTGThemeInactiveColor = @"inactiveColor";
static NSString * const kTGThemeDownvoteColor = @"downvoteColor";
static NSString * const kTGThemeSaveColor = @"saveColor";
static NSString * const kTGThemeStickyColor = @"stickyColor";

static NSString * const kTGThemeSeparatorColor = @"separatorColor";
static NSString * const kTGThemeShadowColor = @"shadowColor";
static NSString * const kTGThemeShadowBorderColor = @"shadowBorderColor";
static NSString * const kTGThemeDimmerColor = @"shadeColor";

@interface ThemeManager : NSObject

@property (strong, nonatomic) NSDictionary *theme;

+ (ThemeManager *)sharedManager;

- (void) setCurrentTheme:(NSString *)themeName;

+ (NSString *) stringForKey:(NSString *)key;
+ (UIColor *) colorForKey:(NSString *)key;

+ (NSString *) darkOrLight;

+ (UIStatusBarStyle) statusBarStyle;
+ (UIBarStyle) uiBarStyle;
+ (NSInteger) scrollViewIndicatorStyle;

+ (void) styleSmallcapsHeader:(UILabel *)label;
+ (void) styleSmallcapsButton:(UIButton *)button;

@end
