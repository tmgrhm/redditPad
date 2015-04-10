//
//  TGCreated.m
//  redditPad
//
//  Created by Tom Graham on 08/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGCreated.h"

@implementation TGCreated

- (instancetype) initFromDictionary:(NSDictionary *)dict
{
	self = [super initFromDictionary:dict];
	if (!self) {
		return nil;
	}
	
	self.creationDate = [NSDate dateWithTimeIntervalSince1970:[dict[@"data"][@"created_utc"] integerValue]];
	
	return self;
}

@end
