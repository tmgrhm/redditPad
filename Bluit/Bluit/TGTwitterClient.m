//
//  TGTwitterClient.m
//  redditPad
//
//  Created by Tom Graham on 20/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGTwitterClient.h"

#import "TGAPIClient+Private.h"

static NSString * const kBaseURLString = @"http://www.twitter.com/";
static NSString * const kBaseHTTPSURLString = @"https://api.twitter.com/1.1/";

// OAuth parameters
static NSString * const client_id = nil;
static NSString * const kConsumerKey = @"FlIUPfZTkKgRyJy1XkiEOaf82";
static NSString * const kConsumerSecret = @"T2WoH8DQRRa6OSy9rp9EYIcFY52S3lWhdSp5v4gmAi0QgifqlF";
static NSString * const oAuthState = nil;
static NSString * const kURIRedirectPath = nil;

@implementation TGTwitterClient

+ (instancetype) sharedClient
{
	static TGTwitterClient *sharedClient = nil;
	static dispatch_once_t oncePredicate;
	dispatch_once(&oncePredicate, ^{
		sharedClient = [TGTwitterClient new];
	});
	
	return sharedClient;
}

- (instancetype) init
{
	self = [super init];
	if (self)
	{
		self.currentTokenExpirationDate = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@-currentTokenExpirationDate", NSStringFromClass([self class])]];
		if (self.currentTokenExpirationDate == nil) self.currentTokenExpirationDate = [NSDate dateWithTimeIntervalSince1970:0]; // if nil, needs creating
		self.accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@-accessToken", NSStringFromClass([self class])]];
		
		self.baseURLString = [self httpsBaseURLString];
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
	// TODO
	return nil;
}

#pragma mark - Authentication

- (void) refreshOAuthTokenWithSuccess:(void (^)())success
{
	// application-only oAuth
	// https://dev.twitter.com/oauth/application-only
	
	NSString *accessURL = @"https://api.twitter.com/oauth2/token?grant_type=client_credentials";
	NSDictionary *parameters = @{@"grant_type": @"client_credentials"};
	
	[self.manager.requestSerializer setAuthorizationHeaderFieldWithUsername:kConsumerKey password:kConsumerSecret]; // Base64 encodes it
	
	__weak __typeof(self)weakSelf = self;
	[self.manager POST:accessURL	// SHOULD be self.manager: want to bypass expiredToken check
			parameters:parameters
			   success:^(NSURLSessionDataTask *task, id responseObject) {
				   if ([responseObject[@"token_type"] isEqualToString:@"bearer"])
				   {
					   NSLog(@"Twitter access token refreshed");
					   weakSelf.accessToken = responseObject[@"access_token"];
					   weakSelf.currentTokenExpirationDate = [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24 * 7 * 4]; // refresh each month — shouldn't ever expire though
				   }
				   success();
			   }
			   failure:^(NSURLSessionDataTask *task, NSError *error) {
				   [weakSelf failureWithError:error];
			   }];
}

#pragma mark - Tweet

- (void) tweetWithID:(NSString *)tweetID success:(void (^)(id responseObject))success
{
	// https://dev.twitter.com/rest/reference/get/statuses/show/%3Aid
	
	NSString *url = [NSString stringWithFormat:@"%@statuses/show.json", self.baseURLString];
	NSDictionary *parameters = @{@"id": tweetID,
								 @"trim_user": @"false",
								 @"include_my_retweet": @"false",
								 @"include_entities": @"true"};
	
	[self GET:url
   parameters:parameters
	  success:^(NSURLSessionDataTask *task, id responseObject) {
		  // TODO
//		  NSLog(@"%@", responseObject);
		  success(responseObject);
	  }
	  failure:^(NSURLSessionDataTask *task, NSError *error) {
		  // TODO
		  [self failureWithError:error];
	  }];
}

#pragma mark - Detecting Link Types

- (BOOL) URLisTwitterLink:(NSURL *)url
{
	if ([url.host isEqualToString:@"twitter.com"]) return YES;
	
	return NO;
}

#pragma mark - Convenience

- (NSString *) tweetIDfromLink:(NSURL *)url
{
	NSString *path = url.path;
	
	NSRange statusRange = [path rangeOfString:@"status/"];
	NSInteger idLocation = statusRange.location + statusRange.length;

	NSString *tweetID = [path substringFromIndex:idLocation];
	
	return tweetID;
}

@end
