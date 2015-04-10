//
//  TGVotable.h
//  redditPad
//
//  Created by Tom Graham on 08/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGCreated.h"

typedef NS_ENUM(NSUInteger, TGVoteStatus)
{
	TGVoteStatusNone,
	TGVoteStatusUpvoted,
	TGVoteStatusDownvoted
};

@interface TGVotable : TGCreated

@property (nonatomic, assign) NSInteger score;
@property (nonatomic) TGVoteStatus voteStatus;

- (instancetype) initFromDictionary:(NSDictionary *)dict;

- (BOOL) upvoted;
- (BOOL) downvoted;
- (BOOL) voted;

@end
