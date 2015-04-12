//
//  TGSubreddit.m
//  redditPad
//
//  Created by Tom Graham on 10/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGSubreddit.h"

@implementation TGSubreddit

- (instancetype) initSubredditFromDictionary:(NSDictionary *)dict
{
	self = [super initFromDictionary:dict];
	if (!self) {
		return nil;
	}
	
	NSDictionary *data = dict[@"data"];
	
	_displayName =				data[@"display_name"];
	_url =						[NSURL URLWithString:data[@"url"]];;
	_title =					data[@"title"];
	_publicDescription	=		data[@"public_description"];
	_publicDescriptionHTML =	data[@"public_description_html"];
	_nsfw =						[data[@"over18"] boolValue];
	_subscribers =				[data[@"subscribers"] unsignedIntegerValue];
	_sidebar =					data[@"description"];
	_sidebarHTML =				data[@"description_html"];
	_submitText =				data[@"submit_text"];
	_submitLinkBtnLabel =		data[@"submit_link_label"];
	_submitTextBtnLabel =		data[@"submit_text_label"];
	_userIsSubscriber =			[data[@"user_is_subscriber"] boolValue];
	_userIsContributor =		[data[@"user_is_contributor"] boolValue];
	_userIsModerator =			[data[@"user_is_moderator"] boolValue];
	_userIsBanned =				[data[@"user_is_banned"] boolValue];
	
	_activeUsers =				data[@"accounts_active"] == [NSNull null] ? -1 : [data[@"accounts_active"] integerValue];
	
	if ([data[@"subreddit_type"] isEqualToString:@"public"])
		_subredditType =		TGSubredditPublic;
	else if ([data[@"subreddit_type"] isEqualToString:@"private"])
		_subredditType =		TGSubredditPrivate;
	else if ([data[@"subreddit_type"] isEqualToString:@"restricted"])
		_subredditType =		TGSubredditRestricted;
	else if ([data[@"subreddit_type"] isEqualToString:@"gold_restricted"])
		_subredditType =		TGSubredditGoldRestricted;
	else if ([data[@"subreddit_type"] isEqualToString:@"archived"])
		_subredditType =		TGSubredditArchived;
	
	if ([data[@"submission_type"] isEqualToString:@"any"])
		_submissionType =		TGSubmissionAny;
	else if ([data[@"submission_type"] isEqualToString:@"link"])
		_submissionType =		TGSubmissionLink;
	else if ([data[@"submission_type"] isEqualToString:@"self"])
		_submissionType =		TGSubmissionText;
	
	return self;
}

@end
