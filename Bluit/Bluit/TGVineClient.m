//
//  TGVineClient.m
//  redditPad
//
//  Created by Tom Graham on 24/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGVineClient.h"

#import "TGAPIClient+Private.h"

static NSString * const kBaseURLString = @"http://www.vine.com/";
static NSString * const kBaseHTTPSURLString = @"https://api.vineapp.com/";

@implementation TGVineClient

+ (instancetype) sharedClient
{
	static TGVineClient *sharedClient = nil;
	static dispatch_once_t oncePredicate;
	dispatch_once(&oncePredicate, ^{
		sharedClient = [TGVineClient new];
	});
	
	return sharedClient;
}

- (instancetype) init
{
	self = [super init];
	if (self)
	{
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

#pragma mark - Image

- (void) mp4URLfromVineURL:(NSURL *)fullURL success:(void (^)(NSURL *vineURL))success
{
	NSString *vineID = [self vineIDfromLink:fullURL]; // get the vineID
	if (vineID)
	{
		[self vineDataWithID:vineID success:^(id responseObject) { // get the vineData from the API
			NSString *vineURLstring = responseObject[@"data"][@"records"][0][@"videoUrl"]; // get default image link
			
			NSString *pattern = @"mp4\?.*";
			NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
			vineURLstring = [regex stringByReplacingMatchesInString:vineURLstring options:0 range:NSMakeRange(0, [vineURLstring length]) withTemplate:@"mp4"];
			
			NSURL *vineURL = [NSURL URLWithString:vineURLstring];
			NSLog(@"directImageURL retrieved from Vine API: %@", vineURL);
			success(vineURL);
		}];
	}
}

- (void) vineDataWithID:(NSString *)vineID success:(void (^)(id responseObject))success
{
	NSString *url = [NSString stringWithFormat:@"%@timelines/posts/s/%@", self.baseURLString, vineID];
	
	[self GET:url
   parameters:nil
	  success:^(NSURLSessionDataTask *task, id responseObject) {
//			NSLog(@"%@", responseObject);
		  success(responseObject);
	  }
	  failure:^(NSURLSessionDataTask *task, NSError *error) {
		  // TODO
		  [self failureWithError:error];
	  }];
}

#pragma mark - Detecting Link Types

- (BOOL) URLisVineLink:(NSURL *)url
{
	if ([url.host containsString:@"vine.co"] && [url.path hasPrefix:@"/v/"]) return YES;
	return NO;
}

#pragma mark - Convenience

- (NSString *) vineIDfromLink:(NSURL *)url
{
	NSString *path = url.path;
	
	NSString *imageID = [path stringByReplacingOccurrencesOfString:@"/v/" withString:@""];
	if (path.length - imageID.length == 3)
		return [imageID stringByReplacingOccurrencesOfString:@"/" withString:@""];
	
	return nil;
}


@end
