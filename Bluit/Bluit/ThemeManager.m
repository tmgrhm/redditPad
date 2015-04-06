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

+ (UIStatusBarStyle) statusBarStyle // TODO returntype
{
	NSString *themeName = [self sharedManager].theme[@"themeName"];
	
	return [themeName isEqualToString:darkTheme] ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

+ (UIColor *) colorForKey:(NSString *)key
{
	NSDictionary *theme = [self sharedManager].theme;
	NSString *hexString = [theme objectForKey:key];
	UIColor *color = [UIColor colorWithHexString:hexString];
	return color;
}

+ (UIColor *) backgroundColor {
	return [self colorForKey:@"backgroundColor"];
}

+ (UIColor *) textColor {
	return [self colorForKey:@"textColor"];
}

+ (UIColor *) secondaryTextColor {
	return [self colorForKey:@"secondaryTextColor"];
}

+ (UIColor *) contentBackgroundColor {
	return [self colorForKey:@"contentBackgroundColor"];
}

+ (UIColor *) tintColor {
	return [self colorForKey:@"tintColor"];
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
