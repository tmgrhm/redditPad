//
//  TGLink.m
//  redditPad
//
//  Created by Tom Graham on 10/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGLink.h"

#import <MWFeedParser/NSString+HTML.h>

@implementation TGLink

- (instancetype) initLinkFromDictionary:(NSDictionary *)dict
{
	self = [super initFromDictionary:dict];
	if (!self) {
		return nil;
	}
	
	NSDictionary *data = dict[@"data"];
	
	_title =				[data[@"title"] stringByDecodingHTMLEntities];
	_totalComments =	[data[@"num_comments"] unsignedIntegerValue];
	_subreddit =			data[@"subreddit"];
	_author =			data[@"author"];
	_domain =			data[@"domain"];
	_url =				[NSURL URLWithString:data[@"url"]];
	_edited =			[data[@"edited"] boolValue];
	_editDate =			_edited ? [NSDate dateWithTimeIntervalSince1970:[data[@"edited"] unsignedIntegerValue]] : nil;
	_selfpost =			[data[@"is_self"] boolValue];
	_hidden =			[data[@"hidden"] boolValue];
	_nsfw =				[data[@"over_18"] boolValue];
	_sticky =			[data[@"stickied"] boolValue];
	_viewed =			[data[@"visited"] boolValue];
	
	NSString *selfText = data[@"selftext"];
	if (selfText)
	{
		selfText = [selfText stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
		selfText = [selfText stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
		selfText = [selfText stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
	}
	_selfText =		data[@"selftext"];
	_selfTextHTML =	data[@"selftext_html"] == [NSNull null] ? @"" : [data[@"selftext_html"] stringByDecodingHTMLEntities];
	
	NSString *lastPathComponent = _url.lastPathComponent;
	_isImageLink = [lastPathComponent hasSuffix:@".png"] || [lastPathComponent hasSuffix:@".jpg"] || [lastPathComponent hasSuffix:@".jpeg"];
	
	_thumbnailURL = _selfpost ? nil : [NSURL URLWithString:data[@"thumbnail"]];
	
	return self;
}

@end