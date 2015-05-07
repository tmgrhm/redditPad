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
	[self.thumbnail setImage:nil];
}

@end
