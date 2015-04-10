//
//  TGMoreComments.m
//  redditPad
//
//  Created by Tom Graham on 10/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGMoreComments.h"

@implementation TGMoreComments

- (instancetype) initFromDictionary:(NSDictionary *)dict
{
	self = [super initFromDictionary:dict];
	if (!self) {
		return nil;
	}
	
	NSDictionary *data = dict[@"data"];
	
	_childrenIDs = data[@"children"];
	_numChildren = [data[@"title"] integerValue];
	_parentID = data[@"parent_id"];
	
	return self;
}

@end
