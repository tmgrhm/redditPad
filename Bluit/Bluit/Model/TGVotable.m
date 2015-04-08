//
//  TGVotable.m
//  redditPad
//
//  Created by Tom Graham on 08/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGVotable.h"

@implementation TGVotable

- (BOOL) upvoted
{
	return self.voteStatus == TGVoteStatusUpvoted;
}

- (BOOL) downvoted
{
	return self.voteStatus == TGVoteStatusDownvoted;
}

- (BOOL) voted
{
	return !(self.voteStatus == TGVoteStatusNone);
}

@end
