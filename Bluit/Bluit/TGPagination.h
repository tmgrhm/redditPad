//
//  TGPagination.h
//  redditPad
//
//  Created by Tom Graham on 22/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGSubreddit.h"
#import "TGLink.h"

@interface TGPagination : NSObject

@property (nonatomic, strong) NSString *subreddit;
@property (nonatomic) TGSubredditSort sort;
@property (nonatomic) TGSubredditSortTimeframe timeframe;
@property (nonatomic, strong) TGLink *afterLink;

@end
