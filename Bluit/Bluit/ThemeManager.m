//
//  ThemeManager.m
//  redditPad
//
//  Created by Tom Graham on 26/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "ThemeManager.h"

#import "UIColor+HexColors.h"

@interface ThemeManager ()

@end

@implementation ThemeManager

+ (ThemeManager *)sharedManager
{
	static ThemeManager *sharedManager = nil;
	if (sharedManager == nil)
	{
		sharedManager = [[ThemeManager alloc] init];
	}
	return sharedManager;
}

- (id)init
{
	if ((self = [super init]))
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString *themeName = [defaults objectForKey:@"theme"] ? : kTGThemeDefault; // TODO
		[self setCurrentTheme:themeName];
	}
	return self;
}

- (void) setCurrentTheme:(NSString *)themeName
{
	[[NSUserDefaults standardUserDefaults] setObject:themeName forKey:@"theme"];
	NSString *path = [[NSBundle mainBundle] pathForResource:themeName ofType:@"plist"];
	self.theme = [NSDictionary dictionaryWithContentsOfFile:path];
	
	NSNotification *themeChangeNotification = [NSNotification notificationWithName:kThemeDidChangeNotification object:nil];
	[[NSNotificationQueue defaultQueue] enqueueNotification:themeChangeNotification postingStyle:NSPostWhenIdle];
}

#pragma mark - Utility
+ (NSString *) stringForKey:(NSString *)key
{
	NSDictionary *theme = [self sharedManager].theme;
	return [theme objectForKey:key];
}

+ (UIColor *) colorForKey:(NSString *)key
{
	UIColor *color = [UIColor colorWithHexString:[self stringForKey:key]];
	return color;
}

#pragma mark - Data Accessors

+ (NSString *) darkOrLight
{
	return [self stringForKey:@"darkOrLight"];
}

+ (UIStatusBarStyle) statusBarStyle // TODO enum
{
	return [[self darkOrLight] isEqualToString:@"dark"] ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

+ (UIBarStyle) uiBarStyle // TODO enum
{
	return [[self darkOrLight] isEqualToString:@"dark"] ? UIBarStyleBlack : UIBarStyleDefault;
}

+ (NSInteger) scrollViewIndicatorStyle
{
	return [[self darkOrLight] isEqualToString:@"dark"] ? UIScrollViewIndicatorStyleWhite : UIScrollViewIndicatorStyleDefault;
}

#pragma mark - Styling methods

+ (void) styleSmallcapsHeader:(UILabel *)label
{
	label.textColor = [ThemeManager colorForKey:kTGThemeSmallcapsHeaderColor];
	label.alpha = 0.5f;
	NSMutableAttributedString *mutAttrStr = [label.attributedText mutableCopy];
	[mutAttrStr addAttribute:NSKernAttributeName
						 value:@(1.5)
						 range:NSMakeRange(0, mutAttrStr.length)];
	label.attributedText = mutAttrStr;
}

+ (void) styleSmallcapsButton:(UIButton *)button // TODO setTitle:(NSString *)title andStyleSmallcapsButton:(UIButton *)button
{
	button.tintColor = [ThemeManager colorForKey:kTGThemeTintColor];
	NSMutableAttributedString *mutAttrStr = [button.titleLabel.attributedText mutableCopy];
	[mutAttrStr addAttribute:NSKernAttributeName
					   value:@(1.5)
					   range:NSMakeRange(0, mutAttrStr.length)];
	[button setAttributedTitle:mutAttrStr forState:UIControlStateNormal];
}

@end
