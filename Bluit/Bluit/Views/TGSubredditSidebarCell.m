//
//  TGSubredditSidebarCell.m
//  redditPad
//
//  Created by Tom Graham on 23/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGSubredditSidebarCell.h"

#import "ThemeManager.h"

@implementation TGSubredditSidebarCell

- (void)awakeFromNib {
    // Initialization code
	
	self.sidebarContent.textContainerInset = UIEdgeInsetsMake(-2, -4, 0, 0);
	
	[ThemeManager styleSmallcapsHeader:self.sidebarHeader];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];	

    // Configure the view for the selected state
}

@end
