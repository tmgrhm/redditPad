//
//  TGSubredditSidebarCell.h
//  redditPad
//
//  Created by Tom Graham on 23/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TGSubredditSidebarCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *sidebarHeader;
@property (weak, nonatomic) IBOutlet UITextView *sidebarContent;
@property (weak, nonatomic) IBOutlet UIView *sidebarHeaderBG;

@end
