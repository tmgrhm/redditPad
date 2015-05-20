//
//  TGRedditClient.m
//  redditPad
//
//  Created by Tom Graham on 03/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGRedditClient.h"

#import "TGAPIClient+Private.h"

static NSString * const kBaseURLString = @"http://www.reddit.com/";
static NSString * const kBaseHTTPSURLString = @"https://oauth.reddit.com/";

// OAuth parameters
static NSString * const client_id = @"l5iDc07xOgRpug";
static NSString * const oAuthState = @"login";
static NSString * const kURIRedirectPath = @"redirect";
static NSString * const scope = @"identity,edit,history,mysubreddits,read,report,save,submit,subscribe,vote";

@interface TGRedditClient ()

@end

@implementation TGRedditClient

+ (instancetype) sharedClient
{
	static TGRedditClient *sharedClient = nil;
	static dispatch_once_t oncePredicate;
	dispatch_once(&oncePredicate, ^{
		sharedClient = [TGRedditClient new];
	});
	
	return sharedClient;
}

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		self.currentTokenExpirationDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentTokenExpirationDate"];
		self.accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"accessToken"];
		self.refreshToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"refreshToken"];
	}
	return self;
}

#pragma mark - Values

- (NSString *) standardBaseURLString {
	return kBaseURLString;
}
- (NSString *) httpsBaseURLString {
	return kBaseHTTPSURLString;
}
- (NSString *) clientID {
	return client_id;
}

- (NSString *) uriScheme {
	return kURIscheme;
}
- (NSString *) uriRedirectPath {
	return kURIRedirectPath;
}
- (NSString *) oAuthState {
	return oAuthState;
}

- (NSURL *) oAuthLoginURL
{
	// https://github.com/reddit/reddit/wiki/OAuth2#authorization
	
	NSString *urlString = [NSString stringWithFormat:@"https://www.reddit.com/api/v1/authorize.compact?client_id=%@&response_type=code&state=%@&redirect_uri=%@://%@&duration=permanent&scope=%@", client_id, oAuthState, kURIscheme, kURIRedirectPath, scope];
	NSURL *url = [NSURL URLWithString:urlString];
	return url;
}

#pragma mark - Listings

- (void) requestSubredditWithPagination:(TGPagination *)pagination withCompletion:(TGListingCompletionBlock)completion;
{
	NSString *path = [NSString stringWithFormat:@"%@%@.json", pagination.subreddit, [[TGSubreddit sortStringFromSubredditSort:pagination.sort] lowercaseString]];
	NSMutableDictionary *parameters = [NSMutableDictionary new];
	
	// http://www.reddit.com/r/unitedkingdom/controversial/?sort=controversial&t=month
	
	if (pagination.afterLink)	[parameters setObject:pagination.afterLink.fullname forKey:@"after"];
	if (pagination.sort)
	{
		[parameters setObject:[TGSubreddit sortStringFromSubredditSort:pagination.sort] forKey:@"sort"];
		if (pagination.timeframe)	[parameters setObject:[TGSubreddit sortTimeframeStringFromSubredditSortTimeframe:pagination.timeframe] forKey:@"t"];
	}
	
	[self requestListing:path withParameters:parameters completion:completion];
}

- (void) requestListing:(NSString *)path withParameters:(NSDictionary *)parameters completion:(TGListingCompletionBlock)completion	// TODO improve
{
	NSString *urlString = [NSString stringWithFormat:@"%@%@", self.baseURLString, path];
	NSLog(@"Client requesting: %@", urlString);
	
	[self GET:urlString
   parameters:parameters
	  success:^(NSURLSessionDataTask *task, id responseObject) {
		  NSDictionary *responseDict = (NSDictionary *)responseObject;
		  NSMutableArray *listing = [NSMutableArray new];
		  
		  for (id item in responseDict[@"data"][@"children"])
		  {
			  [listing addObject:[[TGLink new] initLinkFromDictionary:item]];
		  }
		  
		  completion([NSArray arrayWithArray:listing], nil);
	  }
	  failure:^(NSURLSessionDataTask *task, NSError *error) {
		  [self failureWithError:error];
		  completion(nil, error);
	  }];
}

#pragma mark - Links

- (void) requestCommentsForLink:(TGLink *)link withCompletion:(void (^)(NSArray* comments))completion
{
	NSLog(@"requesting comments for: %@", link.id);
	
	NSString *urlString = [NSString stringWithFormat:@"%@/r/%@/comments/%@.json", self.baseURLString, link.subreddit, link.id];
	
	[self GET:urlString
   parameters:nil
	  success:^(NSURLSessionDataTask *task, id responseObject){
		  id comments = [responseObject lastObject][@"data"][@"children"];
		  completion(comments);
	  }
	  failure:^(NSURLSessionDataTask *task, NSError *error){
		  // TODO
		  [self failureWithError:error];
	  }
	 ];
}

#pragma mark - Subreddits

- (NSURL *) urlToSubreddit:(NSString *)subreddit
{
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@://showSubreddit?name=%@", [self uriScheme], subreddit]];
}

- (void)retrieveUserSubscriptionsWithCompletion:(void (^)(NSArray *subreddits))completion
{
	NSLog(@"retrievingUserSubs");
	
	NSString *urlString = @"mine/subscriber.json?limit=100"; // TODO get all
	[self retrieveSubreddits:urlString withCompletion:completion];
}

- (void)retrieveSubreddits:(NSString *)path withCompletion:(void (^)(NSArray *subreddits))completion
{
	NSString *url = [self.baseURLString stringByAppendingString:[NSString stringWithFormat:@"subreddits/%@", path]];
	[self GET:url
   parameters:nil
	  success:^(NSURLSessionDataTask *task, id responseObject)
	 {
		 NSArray *responseSubs = responseObject[@"data"][@"children"];
		 NSMutableArray *subreddits = [NSMutableArray new];
		 for (NSDictionary *child in responseSubs)
		 {
			 TGSubreddit *sub = [[TGSubreddit alloc] initSubredditFromDictionary:child];
			 [subreddits addObject:sub];
		 }
		 
		 NSLog(@"Retrieved %lu subreddits", (unsigned long)subreddits.count);
		 completion(subreddits);
	 }
	  failure:^(NSURLSessionDataTask *task, NSError *error)
	 {
		 // TODO
		 [self failureWithError:error];
	 }
	 ];
}

- (void) getSubredditInfoFor:(NSString *)subreddit withCompletion:(void (^)(TGSubreddit *subreddit))completion
{
	subreddit = [subreddit stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""]; // remove leading slash
	NSString *url = [NSString stringWithFormat:@"%@%@about", self.baseURLString, subreddit];
	
	[self GET:url
	parameters:nil
	   success:^(NSURLSessionDataTask *task, id responseObject) {
		   TGSubreddit *resultSubreddit = [[TGSubreddit alloc] initSubredditFromDictionary:responseObject];
		   completion(resultSubreddit);
	   } failure:^(NSURLSessionDataTask *task, NSError *error) {
		   // TODO
		   [self failureWithError:error];
	   }];

}

#pragma mark - Report

- (void) hide:(TGThing *)thing
{
	NSString *url = [NSString stringWithFormat:@"%@api/hide", self.baseURLString];
	NSDictionary *parameters = @{@"id" : thing.fullname};
	
	[self POST:url
	parameters:parameters
	   success:^(NSURLSessionDataTask *task, id responseObject) {
		   // TODO
	   } failure:^(NSURLSessionDataTask *task, NSError *error) {
		   // TODO
		   [self failureWithError:error];
	   }];
}

- (void) unhide:(TGThing *)thing
{
	NSString *url = [NSString stringWithFormat:@"%@api/unhide", self.baseURLString];
	NSDictionary *parameters = @{@"id" : thing.fullname};
	
	[self POST:url
	parameters:parameters
	   success:^(NSURLSessionDataTask *task, id responseObject) {
		   // TODO
	   } failure:^(NSURLSessionDataTask *task, NSError *error) {
		   // TODO
		   [self failureWithError:error];
	   }];
}


#pragma mark - Save

- (void) save:(TGThing *)thing
{
	NSString *url = [NSString stringWithFormat:@"%@api/save", self.baseURLString];
	NSDictionary *parameters = @{@"id" : thing.fullname};
	
	[self POST:url
	parameters:parameters
	   success:^(NSURLSessionDataTask *task, id responseObject) {
		   // TODO
	   } failure:^(NSURLSessionDataTask *task, NSError *error) {
		   // TODO
		   [self failureWithError:error];
	   }];
}

- (void) unsave:(TGThing *)thing
{
	NSString *url = [NSString stringWithFormat:@"%@api/unsave", self.baseURLString];
	NSDictionary *parameters = @{@"id" : thing.fullname};
	
	[self POST:url
	parameters:parameters
	   success:^(NSURLSessionDataTask *task, id responseObject) {
		   // TODO
	   } failure:^(NSURLSessionDataTask *task, NSError *error) {
		   // TODO
		   [self failureWithError:error];
	   }];
}

#pragma mark - Voting

- (void) vote:(TGThing *)thing direction:(TGVoteStatus)vote
{
	NSString *url = [NSString stringWithFormat:@"%@api/vote", self.baseURLString];
	NSDictionary *parameters = @{@"id":		thing.fullname,
								 @"dir":		@(vote).stringValue}; // TODO vote direction
	
	[self POST:url
	parameters:parameters
	   success:^(NSURLSessionDataTask *task, id responseObject) {
		   // TODO
	   } failure:^(NSURLSessionDataTask *task, NSError *error) {
		   // TODO
		   [self failureWithError:error];
	   }];
}

#pragma mark - Subscribe

- (void) subscribe:(TGSubreddit *)subreddit
{
	NSString *url = [NSString stringWithFormat:@"%@api/subscribe", self.baseURLString];
	
	NSString *action = subreddit.userIsSubscriber ? @"unsub" : @"sub";
	NSDictionary *parameters = @{@"sr" : subreddit.fullname,
								 @"action" : action};
	
	[self POST:url
	parameters:parameters
	   success:^(NSURLSessionDataTask *task, id responseObject) {
		   NSLog(@"Success!\n%@", responseObject);
	   } failure:^(NSURLSessionDataTask *task, NSError *error) {
		   // TODO
		   [self failureWithError:error];
	   }];
}

@end