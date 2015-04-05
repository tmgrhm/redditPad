//
//  TGCommentTableViewCell.m
//  redditPad
//
//  Created by Tom Graham on 13/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGCommentTableViewCell.h"

@implementation TGCommentTableViewCell

- (void)awakeFromNib {
    // Initialization code
	
	self.bodyLabel.textContainerInset = UIEdgeInsetsMake(-2, -4, 0, 0); // TODO
	self.originalLeftMargin = self.leftMargin.constant;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (CGFloat) calculateHeightForConfiguredCell
{
	[self.bodyLabel setNeedsLayout];
	[self.bodyLabel layoutIfNeeded];
	
	CGFloat height = [self.bodyLabel sizeThatFits:CGSizeMake(CGRectGetWidth(self.bodyLabel.frame), FLT_MAX)].height;
	height += self.topMargin.constant +
				self.midMargin.constant +
				self.metaHeight.constant +
				self.btmMargin.constant;
	
	return height;
}

@end
