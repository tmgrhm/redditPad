//
//  TGVotable.m
//  redditPad
//
//  Created by Tom Graham on 08/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGVotable.h"

@implementation TGVotable

- (instancetype) initFromDictionary:(NSDictionary *)dict
{
	self = [super initFromDictionary:dict];
	if (!self) {
		return nil;
	}
	
	_score = [dict[@"data"][@"score"] integerValue];
	
	id likes = dict[@"data"][@"likes"];
	if (likes == [NSNull null])			_voteStatus = TGVoteStatusNone;
	else if ([likes boolValue] == YES)	_voteStatus = TGVoteStatusUpvoted;
	else								_voteStatus = TGVoteStatusDownvoted;
	
	return self;
}

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
