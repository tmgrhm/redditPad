//
//  FrontPageViewController.h
//  redditPad
//
//  Created by Tom Graham on 03/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TGSubredditListViewController.h"

@interface FrontPageViewController : UIViewController <SubredditDelegate>

@property (strong, nonatomic) NSString *subreddit;

@end

