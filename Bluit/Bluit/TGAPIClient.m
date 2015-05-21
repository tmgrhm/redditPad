//
//  TGAPIClient.m
//  redditPad
//
//  Created by Tom Graham on 19/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGAPIClient.h"
#import "TGAPIClient+Private.h"

@interface TGAPIClient ()

@end

@implementation TGAPIClient

+ (instancetype) sharedClient
{
	static TGAPIClient *sharedClient = nil;
	static dispatch_once_t oncePredicate;
	dispatch_once(&oncePredicate, ^{
		sharedClient = [TGAPIClient new];
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
		self.baseURLString = [self standardBaseURLString];
	}
	
	return self;
}

#pragma mark - Values

- (void) setBaseURLString:(NSString *)baseURLString {
	_baseURLString = baseURLString;
}

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

#pragma mark - Authentication

- (NSURL *) oAuthLoginURL
{
	// TODO http://stackoverflow.com/questions/1034373/creating-an-abstract-class-in-objective-c
	return [NSURL new];
}

- (void) refreshOAuthTokenWithSuccess:(void (^)())success
{
	self.isRefreshingToken = YES;
	// TODO handle currentTokenExpirationDate = nil
	
	if (![self accessTokenHasExpired])
	{
		NSLog(@"date has not passed\n%@\n%f", self.currentTokenExpirationDate, [self.currentTokenExpirationDate timeIntervalSinceNow]); // TODO
		return;
	}
	
	NSLog(@"date has passed, token needs refreshing (%@ — %f seconds ago)", self.currentTokenExpirationDate, [self.currentTokenExpirationDate timeIntervalSinceNow]); // TODO
	
	NSString *accessURL = @"https://www.reddit.com/api/v1/access_token";
	NSDictionary *parameters = @{@"grant_type" :	@"refresh_token",
								 @"refresh_token" :	self.refreshToken};
	[self.manager.requestSerializer setAuthorizationHeaderFieldWithUsername:[self clientID]
																   password:@""]; // password empty due to being a confidential client
	__weak __typeof(self)weakSelf = self;
	[self.manager POST:accessURL	// SHOULD be self.manager: want to bypass expiredToken check
			parameters:parameters
			   success:^(NSURLSessionDataTask *task, id responseObject) {
				   // TODO handle errors as per https://github.com/reddit/reddit/wiki/OAuth2#refreshing-the-token
				   weakSelf.accessToken = responseObject[@"access_token"];
				   weakSelf.currentTokenExpirationDate = [NSDate dateWithTimeIntervalSinceNow:[responseObject[@"expires_in"] doubleValue]];
				   NSLog(@"accessToken refreshed");
				   success();
				   weakSelf.isRefreshingToken = NO;
			   }
			   failure:^(NSURLSessionDataTask *task, NSError *error) {
				   [self failureWithError:error];
			   }];
}

- (BOOL) accessTokenHasExpired
{
	if (self.currentTokenExpirationDate == nil) return NO; // TODO
	
	// 10 second buffer to catch slow requests causing 401s
	return [self.currentTokenExpirationDate timeIntervalSinceNow] < 10.0;
}

#pragma mark - Convenience

- (NSString *)valueForKey:(NSString *)key
		   fromQueryItems:(NSArray *)queryItems
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", key];
	NSURLQueryItem *queryItem = [[queryItems
								  filteredArrayUsingPredicate:predicate]
								 firstObject];
	return queryItem.value;
}

- (void) POST:(NSString *)stringURL parameters:(NSDictionary *)parameters success:(void (^)(NSURLSessionDataTask* task, id responseObject))success failure:(void (^)(NSURLSessionDataTask* task, NSError* error))failure
{
	if ([self accessTokenHasExpired])
	{
		/*if ([self isRefreshingToken])
		 {
			// TODO handle isRefreshing properly
			NSLog(@"isRefreshingToken");
			return;
		 }
		 else
		 {*/
		__weak __typeof(self)weakSelf = self;
		[self refreshOAuthTokenWithSuccess:^{
			[weakSelf POST:stringURL parameters:parameters success:success failure:failure];
		}];
		NSLog(@"Retrying because accessTokenHasExpired");
		return;
		//		}
	}
	
	[self.manager POST:stringURL parameters:parameters success:success failure:failure];
}

- (void) GET:(NSString *)stringURL parameters:(NSDictionary *)parameters success:(void (^)(NSURLSessionDataTask* task, id responseObject))success failure:(void (^)(NSURLSessionDataTask* task, NSError* error))failure
{
	if ([self accessTokenHasExpired])
	{
		/*if ([self isRefreshingToken])
		 {
			// TODO handle isRefreshing properly
			NSLog(@"isRefreshingToken");
			return;
		 }
		 else
		 {*/
		__weak __typeof(self)weakSelf = self;
		[self refreshOAuthTokenWithSuccess:^{
			[weakSelf GET:stringURL parameters:parameters success:success failure:failure];
		}];
		NSLog(@"Retrying because accessTokenHasExpired");
		return;
		//		}
	}
	
	[self.manager GET:stringURL parameters:parameters success:success failure:failure];
}

- (void) failureWithError:(NSError *)error
{
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Connection Error"
														message:[error localizedDescription]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
	[alertView show];
	NSLog(@"%@", error);
}

#pragma mark - Setters & Getters

- (void) setAccessToken:(NSString *)accessToken
{
	// TODO remvoe/store more safely? - see https://github.com/AFNetworking/AFOAuth2Manager/blob/30037a691ddd4c94b64772ca125e12fda4d51eda/AFOAuth2Manager/AFOAuth2Manager.m#L340
	// TODO investigate & handle nil/empty cases
	
	_accessToken = accessToken;
	[[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:[NSString stringWithFormat:@"%@-accessToken", NSStringFromClass([self class])]];
	[self.manager.requestSerializer setValue:[NSString stringWithFormat:@"bearer %@", accessToken] forHTTPHeaderField:@"Authorization"];
	
	self.baseURLString = [self httpsBaseURLString]; // switch to oAuth HTTPS URL because we are oAuth'd
}

- (void) setRefreshToken:(NSString *)refreshToken
{
	_refreshToken = refreshToken;
	[[NSUserDefaults standardUserDefaults] setObject:refreshToken forKey:[NSString stringWithFormat:@"%@-refreshToken", NSStringFromClass([self class])]];
}

- (void) setCurrentTokenExpirationDate:(NSDate *)currentTokenExpirationDate
{
	_currentTokenExpirationDate = currentTokenExpirationDate;
	[[NSUserDefaults standardUserDefaults] setObject:currentTokenExpirationDate forKey:[NSString stringWithFormat:@"%@-currentTokenExpirationDate", NSStringFromClass([self class])]];
}

#pragma mark - Errors

- (void) handleError:(NSError *)error
{
	if ([error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey] statusCode] == 403)
	{
		// TODO
	}
	
}

@end
