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
	if		([@"t1" isEqualToString:kind])	_type = TGThingComment;
	else if ([@"t2" isEqualToString:kind])	_type = TGThingUser;
	else if ([@"t3" isEqualToString:kind])	_type = TGThingLink;
	else if ([@"t4" isEqualToString:kind])	_type = TGThingMessage;
	else if ([@"t5" isEqualToString:kind])	_type = TGThingSubreddit;
	else if ([@"more" isEqualToString:kind])_type = TGThingMore;
	
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

@end
