//
//  TGSubreddit.h
//  redditPad
//
//  Created by Tom Graham on 10/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGCreated.h"

typedef NS_ENUM(NSUInteger, TGSubredditType)
{
	TGSubredditPublic,
	TGSubredditPrivate,
	TGSubredditRestricted,
	TGSubredditGoldRestricted,
	TGSubredditArchived
};

typedef NS_ENUM(NSUInteger, TGSubmissionType)
{
	TGSubmissionAny,
	TGSubmissionLink,
	TGSubmissionText
};

typedef NS_ENUM(NSUInteger, TGSubredditSort)
{
	TGSubredditSortHot = 1,
	TGSubredditSortNew,
	TGSubredditSortRising,
	TGSubredditSortControversial,
	TGSubredditSortTop
};

typedef NS_ENUM(NSUInteger, TGSubredditSortTimeframe)
{
	TGSubredditSortHour = 1,
	TGSubredditSortDay,
	TGSubredditSortWeek,
	TGSubredditSortMonth,
	TGSubredditSortYear,
	TGSubredditSortAll
};

static NSString * const kTGSubredditSortStringHot =				@"Hot";
static NSString * const kTGSubredditSortStringNew =				@"New";
static NSString * const kTGSubredditSortStringRising =			@"Rising";
static NSString * const kTGSubredditSortStringControversial =	@"Controversial";
static NSString * const kTGSubredditSortStringTop =				@"Top";

static NSString * const kTGSubredditSortTimeframeStringHour =	@"hour";
static NSString * const kTGSubredditSortTimeframeStringDay =		@"day";
static NSString * const kTGSubredditSortTimeframeStringWeek =	@"week";
static NSString * const kTGSubredditSortTimeframeStringMonth =	@"month";
static NSString * const kTGSubredditSortTimeframeStringYear =	@"year";
static NSString * const kTGSubredditSortTimeframeStringAll =		@"all";

@interface TGSubreddit : TGCreated

@property (nonatomic, copy, readonly) NSString *displayName;
@property (nonatomic, copy, readonly) NSURL *url;
@property (nonatomic, copy, readonly) NSString *title;

@property (nonatomic, copy, readonly) NSString *publicDescription;
@property (nonatomic, copy, readonly) NSString *publicDescriptionHTML;
@property (nonatomic, assign, readonly) TGSubredditType subredditType;
@property (nonatomic, assign, readonly) TGSubmissionType submissionType;

@property (nonatomic, assign, readonly, getter=isNSFW) BOOL nsfw;

@property (nonatomic, assign, readonly) NSInteger activeUsers;
@property (nonatomic, assign, readonly) NSUInteger subscribers;
@property (nonatomic, copy, readonly) NSString *sidebar;
@property (nonatomic, copy, readonly) NSString *sidebarHTML;

@property (nonatomic, copy, readonly) NSString *submitText;
@property (nonatomic, copy, readonly) NSString *submitLinkBtnLabel;
@property (nonatomic, copy, readonly) NSString *submitTextBtnLabel;

@property (nonatomic, assign, readonly) BOOL userIsSubscriber;
@property (nonatomic, assign, readonly) BOOL userIsContributor;
@property (nonatomic, assign, readonly) BOOL userIsModerator;
@property (nonatomic, assign, readonly) BOOL userIsBanned;

- (instancetype) initSubredditFromDictionary:(NSDictionary *)dict;

@end