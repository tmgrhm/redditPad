//
//  TGCommentCell.m
//  redditPad
//
//  Created by Tom Graham on 23/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGCommentCell.h"

@implementation TGCommentCell

- (void)awakeFromNib {
    // Initialization code
	self.originalLeftMargin = self.leftMargin.constant;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	[self.contentView layoutSubviews];
	self.bodyLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.bodyLabel.frame); // TODO figure out equivalent for UITextView
}

@end
