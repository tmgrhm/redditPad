//
//  TGVotable.m
//  redditPad
//
//  Created by Tom Graham on 08/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGVotable.h"

NSString * const kTGVotableDistinguishedMod = @"moderator";
NSString * const kTGVotableDistinguishedAdmin = @"admin";
NSString * const kTGVotableDistinguishedSpecial = @"special";

@implementation TGVotable

- (instancetype) initFromDictionary:(NSDictionary *)dict
{
	self = [super initFromDictionary:dict];
	if (!self) {
		return nil;
	}
	
	NSDictionary *data = dict[@"data"];
	_score =	[data[@"score"] integerValue];
	_saved =	[data[@"saved"] boolValue];
	_gilded =	[data[@"gilded"] integerValue];
	
	id likes = data[@"likes"];
	if (likes == [NSNull null])			_voteStatus = TGVoteStatusNone;
	else if ([likes boolValue] == YES)	_voteStatus = TGVoteStatusUpvoted;
	else								_voteStatus = TGVoteStatusDownvoted;
	
	NSString *dist = data[@"distinguished"];
	if (data[@"distinguished"] == [NSNull null])						_distinguished = TGVotableDistinguishedNone;
	else if	([dist isEqualToString:kTGVotableDistinguishedMod])		_distinguished = TGVotableDistinguishedMod;
	else if ([dist isEqualToString:kTGVotableDistinguishedAdmin])	_distinguished = TGVotableDistinguishedAdmin;
	else if ([dist isEqualToString:kTGVotableDistinguishedSpecial])	_distinguished = TGVotableDistinguishedSpecial;
	
	return self;
}

- (BOOL) isUpvoted
{
	return self.voteStatus == TGVoteStatusUpvoted;
}

- (BOOL) isDownvoted
{
	return self.voteStatus == TGVoteStatusDownvoted;
}

- (BOOL) isVoted
{
	return !(self.voteStatus == TGVoteStatusNone);
}

@end
