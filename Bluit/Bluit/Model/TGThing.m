//
//  TGThing.m
//  redditPad
//
//  Created by Tom Graham on 08/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGThing.h"

@implementation TGThing

- (instancetype) initFromDictionary:(NSDictionary *)dict
{
	self = [super init];
	if (!self) {
		return nil;
	}
	
	self.id = dict[@"data"][@"id"];
	
	NSString *kind = dict[@"kind"];
	if		([kind isEqualToString:kTGThingCommentString])		_type = TGThingComment;
	else if ([kind isEqualToString:kTGThingUserString])			_type = TGThingUser;
	else if ([kind isEqualToString:kTGThingLinkString])			_type = TGThingLink;
	else if ([kind isEqualToString:kTGThingMessageString])		_type = TGThingMessage;
	else if ([kind isEqualToString:kTGThingSubredditString])	_type = TGThingSubreddit;
	else if ([kind isEqualToString:kTGThingMoreString])			_type = TGThingMore;
	
	switch (_type) {
		case TGThingComment:
		case TGThingLink:
			_archived = [dict[@"data"][@"archived"] boolValue];
			break;
		case TGThingSubreddit:
			_archived = [@"archived" isEqualToString:dict[@"data"][@"subreddit_type"]];
			break;
		default:
			// archived not applicable
			break;
	}
	
	return self;
}

- (NSString *)fullname
{
	NSString *name = [NSString stringWithFormat:@"t%lu_%@", (unsigned long)self.type, self.id];
	return name;
}

@end
