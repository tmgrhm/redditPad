//
//  TGTweetView.m
//  redditPad
//
//  Created by Tom Graham on 22/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGTweetView.h"

#import "ThemeManager.h"

@implementation TGTweetView

- (instancetype) init
{
	self = [super init];
	if (self)
	{
		[self loadNib];
	}
	return self;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		[self loadNib];
	}
	return self;
}

- (void) loadNib
{
	[[NSBundle mainBundle] loadNibNamed:@"TGTweetView" owner:self options:nil];
	
	self.clipsToBounds = YES;
	self.contentView.frame = self.bounds;
	self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleHeight;
	
	self.backgroundColor = [ThemeManager colorForKey:kTGThemeFadedBackgroundColor];
	self.userProfileImage.layer.cornerRadius = self.userProfileImage.frame.size.width / 2.0f; // circular
	self.userProfileImage.backgroundColor = [ThemeManager colorForKey:kTGThemeSeparatorColor];
	
	[self setSkeleton:YES];
	
	[self addSubview:self.contentView];
}

- (void) setSkeleton:(BOOL)isSkeletonView
{
	UIColor *backgroundColor, *textColor, *secondaryTextColor;
	
	if (isSkeletonView)
	{
		backgroundColor = [ThemeManager colorForKey:kTGThemeSeparatorColor];
		textColor = backgroundColor;
		secondaryTextColor = backgroundColor;
		
		// placeholder values
		self.userName.text = @"Nova for Reddit";
		self.userScreenname.text = @"@NovaForReddit";
		self.tweetText.text = @"Hey, you shouldn't be here!";
		self.timestamp.text = @"just now";
	}
	else
	{
		backgroundColor = self.backgroundColor;
		textColor = [ThemeManager colorForKey:kTGThemeTextColor];
		secondaryTextColor = [ThemeManager colorForKey:kTGThemeSecondaryTextColor];
	}
	
	self.userName.backgroundColor = backgroundColor;
	self.userScreenname.backgroundColor = backgroundColor;
	self.tweetText.backgroundColor = backgroundColor;
	self.timestamp.backgroundColor = backgroundColor;
	
	self.userName.textColor = textColor;
	self.userScreenname.textColor = secondaryTextColor;
	self.tweetText.textColor = textColor;
	self.timestamp.textColor = secondaryTextColor;
}

- (void) setBackgroundColor:(UIColor *)backgroundColor
{
	[super setBackgroundColor:backgroundColor];
	
	self.contentView.backgroundColor = backgroundColor;
}

@end
