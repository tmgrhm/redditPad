//
//  TGSubredditListViewController.h
//  redditPad
//
//  Created by Tom Graham on 03/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SubredditDelegate <NSObject>

-(void) didSelectSubreddit:(NSString *) subreddit;

@end

@interface TGSubredditListViewController : UIViewController

@property (nonatomic,retain) id<SubredditDelegate> delegate;

- (void) reloadTableViewData;

@end

