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

- (void)awakeFromNib
{
	// these textColors are apparently necessary for setting colour correctly later via attributedText (wtf)
	self.nameLabel.textColor = [ThemeManager textColor];
	self.descriptionLabel.textColor = [ThemeManager secondaryTextColor];
	self.subscribersLabel.textColor = [ThemeManager textColor];
	self.hereNowLabel.textColor = [ThemeManager textColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setNumSubscribers:(unsigned long)subscribers
{
	self.subscribersLabel.attributedText = [self attributedSubscriberStatisticsWithNumber:subscribers text:@" subscribers"];
}

- (void) setNumActiveUsers:(unsigned long)activeUsers
{
	self.hereNowLabel.attributedText = [self attributedSubscriberStatisticsWithNumber:activeUsers text:@" here now"];
}

- (void) setSubscribeButtonTitle:(NSString *)title
{
	self.subscribeButton.titleLabel.text = title;
	[ThemeManager styleSmallcapsButton:self.subscribeButton];
}

#pragma mark - Convenience
- (NSAttributedString *) attributedSubscriberStatisticsWithNumber:(unsigned long)number text:(NSString *)text
{
	NSDictionary *numberAttributes = @{NSForegroundColorAttributeName:[ThemeManager textColor],
									   NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-DemiBold" size:15.0f]};
	NSDictionary *textAttributes = @{NSForegroundColorAttributeName:[ThemeManager secondaryTextColor],
									 NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Regular" size:15.0f]};
	
	NSString *numberStr = [NSString stringWithFormat:@"%lu", (unsigned long) number]; // TODO format nicely with commas
	
	NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:numberStr attributes:numberAttributes];
	NSAttributedString *textStr = [[NSAttributedString alloc] initWithString:text attributes:textAttributes];
	
	[attrStr appendAttributedString:textStr];
	
	return attrStr;
}

@end
