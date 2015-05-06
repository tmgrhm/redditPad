//
//  TGSubredditInfoCell.m
//  redditPad
//
//  Created by Tom Graham on 23/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGSubredditInfoCell.h"

#import "ThemeManager.h"

@implementation TGSubredditInfoCell

- (void)awakeFromNib {
    // Initialization code
	
	self.nameLabel.textColor = [ThemeManager textColor]; // TODO attrText /r/styling
	
	self.descriptionLabel.textColor = [ThemeManager secondaryTextColor];
//	[ThemeManager styleSmallcapsHeader:self.subscribersLabel];
//	[ThemeManager styleSmallcapsHeader:self.hereNowLabel];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setNumSubscribers:(unsigned long)subscribers
{
	self.subscribersLabel.text = [NSString stringWithFormat:@"%lu SUBSCRIBERS", subscribers];
	[ThemeManager styleSmallcapsHeader:self.subscribersLabel];
}

- (void) setNumActiveUsers:(unsigned long)activeUsers
{
	self.hereNowLabel.text = [NSString stringWithFormat:@"%lu HERE NOW", activeUsers];
	[ThemeManager styleSmallcapsHeader:self.hereNowLabel];
}

- (void) setSubscribeButtonTitle:(NSString *)title
{
//	[self.subscribeButton setTitle:title forState:UIControlStateNormal];
	self.subscribeButton.titleLabel.text = title;
	[ThemeManager styleSmallcapsButton:self.subscribeButton];
}

@end
