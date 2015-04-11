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
		NSString *themeName = [defaults objectForKey:@"theme"] ? : defaultTheme; // TODO
		NSString *path = [[NSBundle mainBundle] pathForResource:themeName ofType:@"plist"];
		self.theme = [NSDictionary dictionaryWithContentsOfFile:path];
	}
	return self;
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

+ (UIColor *) backgroundColor {
	return [self colorForKey:@"backgroundColor"];
}

+ (UIColor *) contentBackgroundColor {
	return [self colorForKey:@"contentBackgroundColor"];
}

+ (UIColor *) textColor {
	return [self colorForKey:@"textColor"];
}

+ (UIColor *) secondaryTextColor {
	return [self colorForKey:@"secondaryTextColor"];
}

+ (UIColor *) smallcapsHeaderColor {
	return [self colorForKey:@"smallcapsHeaderColor"];
}

+ (UIColor *) tintColor {
	return [self colorForKey:@"tintColor"];
}

+ (UIColor *) saveColor {
	return [self colorForKey:@"saveColor"];
}

+ (UIColor *) inactiveColor {
	return [self colorForKey:@"inactiveColor"];
}

+ (UIColor *) separatorColor {
	return [self colorForKey:@"separatorColor"];
}

+ (UIColor *) shadowColor {
	return [self colorForKey:@"shadowColor"];
}

+ (UIColor *) shadowBorderColor {
	return [self colorForKey:@"shadowBorderColor"];
}

+ (UIColor *) shadeColor {
	return [self colorForKey:@"shadeColor"];
}


@end
