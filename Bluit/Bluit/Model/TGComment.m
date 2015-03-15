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
		return nil; // TODO handle error better
	}
	
	NSDictionary *data = dict[@"data"];
	
	_body = data[@"body"];
	_bodyHTML = data[@"body_html"];
	_score = [data[@"score"] integerValue]; // TODO deal with negative values
	_scoreHidden = data[@"score_hidden"];
	_author = data[@"author"];
	//	_creationDate = [NSDate ]; TODO
	_edited = data[@"edited"];
	//	_editDate;
	_saved = data[@"saved"];
	
	return self;
}

@end
