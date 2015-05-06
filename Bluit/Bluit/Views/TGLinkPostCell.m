//
//  TGLinkPostCell.m
//  redditPad
//
//  Created by Tom Graham on 25/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGLinkPostCell.h"

@implementation TGLinkPostCell

- (void)awakeFromNib {
    // Initialization code
	self.title.textContainerInset = UIEdgeInsetsMake(-2, -4, 0, 0);
	self.content.textContainerInset = UIEdgeInsetsMake(-2, -4, 0, 0);
	self.metadata.textContainerInset = UIEdgeInsetsMake(-2, -4, 0, 0);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
