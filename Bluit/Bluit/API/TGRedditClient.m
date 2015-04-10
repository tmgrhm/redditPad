//
//  TGRedditClient.m
//  redditPad
//
//  Created by Tom Graham on 03/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TGRedditClient.h"
#import "TGLink.h"

#import "TGWebViewController.h"

#import <AFNetworking/AFHTTPRequestOperation.h>
#import <AFNetworking/AFHTTPSessionManager.h>

static NSString * const BaseURLString = @"http://www.reddit.com/";
static NSString * const BaseHTTPSURLString = @"https://ssl.reddit.com/";

// OAuth parameters
static NSString * const client_id = @"l5iDc07xOgRpug";
static NSString * const oAuthState = @"login";
static NSString * const redirect_uri = @"redditpad://redirect";
static NSString * const scope = @"identity,edit,history,mysubreddits,read,report,save,submit,subscribe,vote";

@interface TGRedditClient ()

@property (strong, nonatomic) AFHTTPRequestSerializer *serializer;
@property (strong, nonatomic) AFHTTPSessionManager *manager;

@property (strong, nonatomic) NSString *modhash;
@property (strong, nonatomic) NSString *sessionIdentifier;
@property (strong, nonatomic) NSString *accessToken;
@property (strong, nonatomic) NSString *refreshToken;

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
    [self requestSubreddit:@"hot" withCompletion:completion];
}

- (void) requestSubreddit:(NSString *)subredditURL withCompletion:(TGListingCompletionBlock)completion
{
	[self requestSubreddit:subredditURL after:nil withCompletion:completion];
}

- (void) requestSubreddit:(NSString *)subredditURL after:(TGLink *)link withCompletion:(TGListingCompletionBlock)completion
{
	NSString *path = [subredditURL stringByAppendingString:@".json"];
	if (link)
	{
		path = [NSString stringWithFormat:@"%@?after=t3_%@", path, link.id]; // TODO better than "?after="
	}
	[self request:path withCompletionBlock:completion];
}

- (void) request:(NSString *)path withCompletionBlock:(TGListingCompletionBlock)completion	// TODO improve
{
	NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", BaseURLString, path]];
	
	NSLog(@"Client requesting: %@", [NSString stringWithFormat:@"%@%@", BaseURLString, path]);
    
	NSURLRequest *request = [NSURLRequest requestWithURL:URL];
	
	AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	operation.responseSerializer = [AFJSONResponseSerializer serializer];
	
	[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
	{
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
		 [self failureWithError:error];
		 completion(nil, error);
	 }];
	
	[operation start];
}

- (void) loginWithUsername:(NSString *)username
				  password:(NSString *)password
			withCompletion:(void (^)(void))completion
{
	NSDictionary *parameters = @{@"user": username,
								 @"passwd": password,
								 @"rem": @"on",
								 @"api_type": @"json"};
	
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
			[self failureWithError:error];
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
	
	NSString *urlString = [BaseURLString stringByAppendingString:@"subreddits/mine/subscriber.json?limit=100"]; // TODO get all
	
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
				   [self failureWithError:error];
			   }
	 ];
}

- (NSURL *) oAuthLoginURL
{
	NSString *authURLString = [NSString stringWithFormat:@"api/v1/authorize.compact?client_id=%@&response_type=code&state=%@&redirect_uri=%@&duration=permanent&scope=%@", client_id, oAuthState, redirect_uri, scope];
	NSString *urlString = [BaseHTTPSURLString stringByAppendingString:authURLString];
	NSURL *url = [NSURL URLWithString:urlString];
	return url;
}

- (void) loginWithOAuthResponse:(NSURL *)url
{
	NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url
												resolvingAgainstBaseURL:NO];
	NSArray *queryItems = urlComponents.queryItems;
	NSString *error = [self valueForKey:@"error" fromQueryItems:queryItems];
	
	if (error)
	{
		NSLog(@"Error: %@", error);
	}
	
	NSString *state = [self valueForKey:@"state" fromQueryItems:queryItems];
	NSString *code = [self valueForKey:@"code" fromQueryItems:queryItems];
	
	if ([state isEqualToString:oAuthState])
	{
		NSString *accessURL = @"https://www.reddit.com/api/v1/access_token";
		NSDictionary *parameters = @{@"grant_type":@"authorization_code",
									 @"code":code,
									 @"redirect_uri":redirect_uri};
		[self.manager.requestSerializer setAuthorizationHeaderFieldWithUsername:client_id
																	   password:@""]; // password empty due to being a confidential client
		[self.manager POST:accessURL
				parameters:parameters
				   success:^(NSURLSessionDataTask *task, id responseObject) {
					   // TODO handle errors as per https://github.com/reddit/reddit/wiki/OAuth2#refreshing-the-token
					   self.accessToken = responseObject[@"access_token"];
					   self.refreshToken = responseObject[@"refresh_token"];
					   // TODO set up refreshing — probably want to store responseObject[@"expires_in"]
					   
					   // TODO use global notification centre to announce login
				   }
				   failure:^(NSURLSessionDataTask *task, NSError *error) {
					   [self failureWithError:error];
				   }];
	}
	else
	{
		NSLog(@"Error: state doesn't match oAuth state, ur bein haxed"); // TODO handle unsafe state
	}
}

- (void) refreshOAuthToken // TODO use this
{
	NSString *accessURL = @"https://www.reddit.com/api/v1/access_token";
	NSDictionary *parameters = @{@"grant_type":@"refresh_token",
								 @"refresh_token":self.refreshToken};
	[self.manager.requestSerializer setAuthorizationHeaderFieldWithUsername:client_id
																   password:@""]; // password empty due to being a confidential client
	[self.manager POST:accessURL
			parameters:parameters
			   success:^(NSURLSessionDataTask *task, id responseObject) {
				   // TODO handle errors as per https://github.com/reddit/reddit/wiki/OAuth2#refreshing-the-token
				   self.accessToken = responseObject[@"access_token"];
			   }
			   failure:^(NSURLSessionDataTask *task, NSError *error) {
				   [self failureWithError:error];
			   }];
}

- (void) requestCommentsForLink:(TGLink *)link withCompletion:(void (^)(NSArray* comments))completion
{
	NSLog(@"requesting comments for: %@", link.id);
		
	NSString *urlString = [NSString stringWithFormat:@"%@/r/%@/comments/%@.json", BaseURLString, link.subreddit, link.id];
	
	[self.manager GET:urlString
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

#pragma mark Convenience

- (NSString *)valueForKey:(NSString *)key
		   fromQueryItems:(NSArray *)queryItems
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", key];
	NSURLQueryItem *queryItem = [[queryItems
								  filteredArrayUsingPredicate:predicate]
								 firstObject];
	return queryItem.value;
}

- (void) failureWithError:(NSError *)error
{
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Connection Error"
														message:[error localizedDescription]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
	[alertView show];
}

@end