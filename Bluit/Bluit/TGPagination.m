//
//  TGPagination.m
//  redditPad
//
//  Created by Tom Graham on 22/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGPagination.h"

@implementation TGPagination

- (instancetype) init
{
	self = [super init];
	if (!self) return nil;
	
	self.sort = TGSubredditSortHot;
	
	return self;
}

- (void) setSubreddit:(NSString *)subreddit
{
	if ([subreddit length] == 0) subreddit = @"/";
	
	_subreddit = subreddit;
}

@end
