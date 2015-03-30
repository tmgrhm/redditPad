//
//  TGRedditClient.m
//  redditPad
//
//  Created by Tom Graham on 03/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGLink.h"
#import "TGRedditClient.h"
#import <AFNetworking/AFHTTPRequestOperation.h>
#import <AFNetworking/AFHTTPSessionManager.h>

static NSString * const BaseURLString = @"http://www.reddit.com/";
static NSString * const BaseHTTPSURLString = @"https://ssl.reddit.com/";

@interface TGRedditClient ()

@property (strong, nonatomic) AFHTTPRequestSerializer *serializer;
@property (strong, nonatomic) AFHTTPSessionManager *manager;
@property (strong, nonatomic) NSString *modhash;
@property (strong, nonatomic) NSString *sessionIdentifier;

@property (strong, nonatomic) NSArray *userSubreddits;

@end

@implementation TGRedditClient

+ (instancetype)sharedClient
{
	static TGRedditClient *sharedClient = nil;
	static dispatch_once_t oncePredicate;
	dispatch_once(&oncePredicate, ^{
		sharedClient = [TGRedditClient new]; // TODO revert to alloc init?
	});
	
	return sharedClient;
}

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		self.serializer = [AFHTTPRequestSerializer serializer];
		self.manager = [AFHTTPSessionManager manager];
	}
	
	return self;
}

- (void) requestFrontPageWithCompletionBlock:(TGListingCompletionBlock)completion
{
    [self request:@"hot" withCompletionBlock:completion];
}

- (void) requestSubreddit:(NSString *)subredditURL withCompletion:(TGListingCompletionBlock)completion
{
	[self request:subredditURL withCompletionBlock:completion];
}

- (void) request:(NSString *)path withCompletionBlock:(TGListingCompletionBlock)completion	// TODO improve
{
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", BaseURLString, path, @".json"]];
	
	NSLog(@"Client requesting: %@", [NSString stringWithFormat:@"%@%@%@", BaseURLString, path, @".json"]);
    
	NSURLRequest *request = [NSURLRequest requestWithURL:URL];
	
	AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	operation.responseSerializer = [AFJSONResponseSerializer serializer];
	
	[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//		NSLog(@"%@", responseObject);
		NSDictionary *responseDict = (NSDictionary *)responseObject;
		
		NSMutableArray *listing = [NSMutableArray new];
		
		for (id item in responseDict[@"data"][@"children"])
		{
			[listing addObject:[[TGLink new] initLinkFromDictionary:item]];
		}
		
		completion([NSArray arrayWithArray:listing], nil);
	}
	 failure:^(AFHTTPRequestOperation *operation, NSError *error)
	 {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Connection Error"
															message:[error localizedDescription]
														   delegate:nil
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
		 [alertView show];
		 completion(nil, error);
	 }];
	
	[operation start];
}

- (void) loginWithUsername:(NSString *)username
				  password:(NSString *)password
			withCompletion:(void (^)(void))completion
{
	NSDictionary *parameters = @{@"user": username, @"passwd": password, @"api_type": @"json"};
	
	NSString *urlString = [BaseHTTPSURLString stringByAppendingString:@"api/login"];
	
	__weak __typeof(self)weakSelf = self;
	
	[self.manager POST:urlString
			parameters:parameters
			   success:^(NSURLSessionDataTask *task, id responseObject)
		{
			NSDictionary *data = (NSDictionary *)responseObject[@"json"][@"data"];
			weakSelf.modhash = data[@"modhash"];
			weakSelf.sessionIdentifier = data[@"cookie"] ?
			[NSString stringWithFormat:@"reddit_session=%@", [data[@"cookie"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] : nil;
			
			NSLog(@"got new session: \"%@\" \nsessionID: \"%@\"", weakSelf.modhash, weakSelf.sessionIdentifier);
			
			[[NSUserDefaults standardUserDefaults] setObject:weakSelf.modhash forKey:@"modhash"];
			[[NSUserDefaults standardUserDefaults] setObject:weakSelf.sessionIdentifier forKey:@"sessionIdentifier"];
			
			[weakSelf setSerializerHTTPHeaders:weakSelf.modhash and:weakSelf.sessionIdentifier];
			completion();
		}
			   failure:^(NSURLSessionDataTask *task, NSError *error)
		{
			NSLog(@"%@", error.description);
		}
	 ];
}

- (void) setSerializerHTTPHeaders:(NSString *)modhash and:(NSString *)sessionIdentifier
{
	[self.serializer setValue:modhash forHTTPHeaderField:@"X-Modhash"];
	[self.serializer setValue:sessionIdentifier forHTTPHeaderField:@"Cookie"];
	
	NSLog(@"set headers: \"%@\" \nsessionID: \"%@\"", modhash, sessionIdentifier);
}

- (void)retrieveUserSubscriptionsWithCompletion:(void (^)(NSArray *subreddits))completion {
	NSLog(@"retrievingUserSubs");
	
	NSString *urlString = [BaseURLString stringByAppendingString:@"subreddits/mine/subscriber.json"];
	
	__weak __typeof(self)weakSelf = self;
	
	[self.manager GET:urlString
			parameters:nil
			   success:^(NSURLSessionDataTask *task, id responseObject){
				   weakSelf.userSubreddits = responseObject[@"data"][@"children"];
				   NSLog(@"Retrieved %lu subreddits", weakSelf.userSubreddits.count);
				   completion(weakSelf.userSubreddits);
			   }
			   failure:^(NSURLSessionDataTask *task, NSError *error){
				   // TODO
				   NSLog(@"%@", error.description);
			   }
	 ];
}



- (void) requestCommentsForLink:(TGLink *)link withCompletion:(void (^)(NSArray* comments))completion
{
	NSLog(@"requesting comments for: %@", link.id);
		
	NSString *urlString = [NSString stringWithFormat:@"%@/r/%@/comments/%@.json", BaseURLString, link.subreddit, link.id];
	
//	__weak __typeof(self)weakSelf = self;
	
	[self.manager GET:urlString
		   parameters:nil
			  success:^(NSURLSessionDataTask *task, id responseObject){
				  id comments = [responseObject lastObject][@"data"][@"children"];
//				  NSLog(@"comments data children: %@", comments);
				  
				  completion(comments);
			  }
			  failure:^(NSURLSessionDataTask *task, NSError *error){
				  // TODO
				  NSLog(@"%@", error.description);
			  }
	 ];
}


@end