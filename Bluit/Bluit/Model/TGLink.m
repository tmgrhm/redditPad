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

	_id = data[@"id"];
	_title = data[@"title"];
	_score = [data[@"score"] integerValue];
	_totalComments = [data[@"num_comments"] integerValue];
	_subreddit = data[@"subreddit"];
	_author = data[@"author"];
	_domain = data[@"domain"];
	_url = [NSURL URLWithString:data[@"url"]];
	_selfText = data[@"selftext"];
	_selfTextHTML = data[@"body_html"];
	_creationDate = [NSDate dateWithTimeIntervalSince1970:[data[@"created_utc"] integerValue]];
	_edited = data[@"edited"];
//	_editDate;
	_selfpost = [_domain containsString:[NSString stringWithFormat:@"self.%@", _subreddit]]; // TODO make safer
	_saved = data[@"saved"];
	_nsfw = data[@"over_18"];
	_sticky = data[@"stickied"];
	_distinguished = data[@"distinguished"];
	_viewed = data[@"visited"];
	
	_thumbnailURL = _selfpost ? nil : [NSURL URLWithString:data[@"thumbnail"]];
	
	return self;
}

@end
