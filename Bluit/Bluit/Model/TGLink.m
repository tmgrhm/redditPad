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
	self = [super initFromDictionary:dict];
	if (!self) {
		return nil;
	}
	
	NSDictionary *data = dict[@"data"];
	
	_title =			data[@"title"];
	_totalComments =	[data[@"num_comments"] unsignedIntegerValue];
	_subreddit =		data[@"subreddit"];
	_author =			data[@"author"];
	_domain =			data[@"domain"];
	_url =				[NSURL URLWithString:data[@"url"]];
	_selfText =			data[@"selftext"];
	_selfTextHTML =		data[@"body_html"];
	_edited =			[data[@"edited"] boolValue];
	_editDate =			_edited ? [NSDate dateWithTimeIntervalSince1970:[data[@"edited"] unsignedIntegerValue]] : nil;
	_selfpost =			[data[@"is_self"] boolValue];
	_hidden =			[data[@"hidden"] boolValue];
	_saved =			[data[@"saved"] boolValue];
	_nsfw =				[data[@"over_18"] boolValue];
	_sticky =			[data[@"stickied"] boolValue];
	_viewed =			[data[@"visited"] boolValue];
	
	_thumbnailURL = _selfpost ? nil : [NSURL URLWithString:data[@"thumbnail"]];
	
	return self;
}

@end