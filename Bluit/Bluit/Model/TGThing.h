//
//  TGThing.h
//  redditPad
//
//  Created by Tom Graham on 08/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TGThingType)
{
	TGThingComment = 1,
	TGThingUser,
	TGThingLink,
	TGThingMessage,
	TGThingSubreddit,
	TGThingMore
};

static NSString * const kTGThingCommentString =		@"t1";
static NSString * const kTGThingUserString =		@"t2";
static NSString * const kTGThingLinkString =		@"t3";
static NSString * const kTGThingMessageString =		@"t4";
static NSString * const kTGThingSubredditString =	@"t5";
static NSString * const kTGThingMoreString =		@"more";

@interface TGThing : NSObject

@property (nonatomic, strong) NSString *id;
@property (nonatomic) TGThingType type;
@property (nonatomic, getter=isArchived) BOOL archived;

- (instancetype) initFromDictionary:(NSDictionary *)dict;

@end
