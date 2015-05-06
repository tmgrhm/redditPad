//
//  TGSubredditInfoViewController.h
//  redditPad
//
//  Created by Tom Graham on 23/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TGSubreddit.h"

@interface TGSubredditInfoViewController : UITableViewController

@property (strong, nonatomic) TGSubreddit *subreddit;

- (void) loadInfoForSubreddit:(NSString *)subredditTitle;

@end
