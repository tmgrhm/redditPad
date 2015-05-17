//
//  TGListingTableViewCell.m
//  redditPad
//
//  Created by Tom Graham on 10/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGListingTableViewCell.h"

@implementation TGListingTableViewCell

- (UIEdgeInsets)layoutMargins
{
	return UIEdgeInsetsZero;
}

- (void) prepareForReuse
{
	self.domain.hidden = NO;
	
	self.thumbnail.image = nil;
	self.thumbnail.backgroundColor = self.backgroundColor;
}

- (void) setBackgroundColor:(UIColor *)backgroundColor
{
	[super setBackgroundColor:backgroundColor];
	
	self.contentView.backgroundColor = backgroundColor;
	self.score.backgroundColor = backgroundColor;
	self.title.backgroundColor = backgroundColor;
	self.subreddit.backgroundColor = backgroundColor;
	self.timestamp.backgroundColor = backgroundColor;
	self.author.backgroundColor = backgroundColor;
	self.domain.backgroundColor = backgroundColor;
	self.totalComments.backgroundColor = backgroundColor;
}

@end
