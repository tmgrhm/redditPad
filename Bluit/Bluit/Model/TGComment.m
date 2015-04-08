//
//  TGComment.m
//  redditPad
//
//  Created by Tom Graham on 13/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGComment.h"

@implementation TGComment

- (instancetype) initCommentFromDictionary:(NSDictionary *)dict
{
	self = [super init];
	if (!self) {
		return nil;
	}
	
	if (![@"t1" isEqualToString:dict[@"kind"]]) // TODO don't use literal string, typedef
	{
//		NSLog(@"TGComment got passed a !t1 object");
		return nil; // TODO handle error better
	}
	
	// BOOLs aren't being handled properly — all become YES even if value is 0
	
	NSDictionary *data = dict[@"data"];
	
	_body =				data[@"body"];
	_bodyHTML =			data[@"body_html"];
	_scoreHidden =		[data[@"score_hidden"]  boolValue];
	_author =			data[@"author"];
	_edited =			[data[@"edited"] boolValue]; // TODO test
	_editDate =			_edited ? [NSDate dateWithTimeIntervalSince1970:[data[@"edited"] integerValue]] : nil; // TODO test
	_saved =			[data[@"saved"] boolValue];
	_parentID =			data[@"parent_id"];
	_indentationLevel = [data[@"indentationLevel"] integerValue];
	
	self.id =			data[@"id"];
	self.score =		[data[@"score"] integerValue];
	self.archived =		[data[@"archived"] boolValue];
	self.creationDate = [NSDate dateWithTimeIntervalSince1970:[data[@"created_utc"] integerValue]];
	
	if ([data[@"replies"] isKindOfClass:NSDictionary.class])
	{
		NSMutableArray *children = [NSMutableArray new];
		NSArray *childrenDicts = data[@"replies"][@"data"][@"children"];
		
		for (id child in childrenDicts)
		{
			NSMutableDictionary *mutableChild = [child mutableCopy];
			mutableChild[@"data"] = [mutableChild[@"data"] mutableCopy];
			mutableChild[@"data"][@"indentationLevel"] = [NSString stringWithFormat:@"%lu", self.indentationLevel + 1];
			TGComment *comment = [[TGComment new] initCommentFromDictionary:mutableChild];
			if (comment)
			{
				[children addObject:comment];
			}
		}
		
		_children = children;
	}

	return self;
}

- (NSUInteger) numReplies
{
	NSUInteger numReplies = self.children.count;
	for (TGComment *child in self.children)
	{
		numReplies += [child numReplies];
	}
	return numReplies;
}

+ (NSArray *) childrenRecursivelyForComment:(TGComment *)comment
{
	NSMutableArray *comments = [NSMutableArray new];
	
	if (comment.children.count > 0)
	{
		NSArray *children = comment.children;
		for (TGComment *child in children)
		{
			[comments addObject:child];
			comments = [[comments arrayByAddingObjectsFromArray:[TGComment childrenRecursivelyForComment:child]] mutableCopy];
		}
	}
	
	return comments;
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"body: %@ \n author:%@ \n indent:%lu \n \t children: %lu", self.body, self.author, self.indentationLevel, self.children.count];
}

@end
