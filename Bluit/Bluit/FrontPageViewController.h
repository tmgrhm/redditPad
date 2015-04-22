//
//  FrontPageViewController.h
//  redditPad
//
//  Created by Tom Graham on 03/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TGLink.h"
#import "TGSubreddit.h"
#import "TGPagination.h"

#import "TGSubredditListViewController.h"

@interface FrontPageViewController : UIViewController <SubredditDelegate>

@property (strong, nonatomic) TGPagination *pagination;

- (void) loadSubreddit:(NSString *)subredditURL;
- (void) loadSubredditWithCurrentPagination;
- (void) loadSubredditAfter:(TGLink *)link;
- (void) loadMore;

@end

