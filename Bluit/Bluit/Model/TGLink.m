//
//  TGLink.m
//  redditPad
//
//  Created by Tom Graham on 10/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGLink.h"

@implementation TGLink

- (instancetype) initLinkFromDictionary:(NSDictionary *)dict
{
	self = [super init];
	if (!self) {
		return nil;
	}
	
	if (![@"t3" isEqualToString:dict[@"kind"]]) // TODO don't use literal string, typedef
	{
		return nil; // TODO handle error better
	}
	
	NSDictionary *data = dict[@"data"];

	_title =			data[@"title"];
	_totalComments =	[data[@"num_comments"] integerValue];
	_subreddit =		data[@"subreddit"];
	_author =			data[@"author"];
	_domain =			data[@"domain"];
	_url =				[NSURL URLWithString:data[@"url"]];
	_selfText =			data[@"selftext"];
	_selfTextHTML =		data[@"body_html"];
	_edited =			[data[@"edited"] boolValue]; // TODO test
	_editDate =			_edited ? [NSDate dateWithTimeIntervalSince1970:[data[@"edited"] integerValue]] : nil; // TODO test
	_selfpost =			[_domain containsString:[NSString stringWithFormat:@"self.%@", _subreddit]]; // TODO make safer
	_saved =			[data[@"saved"] boolValue];
	_nsfw =				[data[@"over_18"] boolValue];
	_sticky =			[data[@"stickied"] boolValue];
	_distinguished =	data[@"distinguished"]; // TODO handle
	_viewed =			[data[@"visited"] boolValue];
	
	self.id =			data[@"id"];
	self.score =		[data[@"score"] integerValue];
	self.archived =		[data[@"archived"] boolValue];
	self.creationDate = [NSDate dateWithTimeIntervalSince1970:[data[@"created_utc"] integerValue]];
	
	_thumbnailURL = _selfpost ? nil : [NSURL URLWithString:data[@"thumbnail"]];
	
	return self;
}

@end
