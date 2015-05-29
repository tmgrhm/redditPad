//
//  TGInstagramClient.m
//  redditPad
//
//  Created by Tom Graham on 23/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGInstagramClient.h"

#import "TGAPIClient+Private.h"

#import "TGMedia.h"

static NSString * const kBaseURLString = @"http://www.instagram.com/";
static NSString * const kBaseHTTPSURLString = @"https://api.instagram.com/v1/";

// OAuth parameters
static NSString * const client_id = @"94127b77e375428e9e64716c7a4fb317";

@implementation TGInstagramClient

+ (instancetype) sharedClient
{
	static TGInstagramClient *sharedClient = nil;
	static dispatch_once_t oncePredicate;
	dispatch_once(&oncePredicate, ^{
		sharedClient = [TGInstagramClient new];
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
- (NSString *) clientID {
	return client_id;
}

#pragma mark - Image

- (void) mediaFromInstagramURL:(NSURL *)fullURL success:(void (^)(NSArray *media))success
{
	NSString *mediaID = [self mediaIDfromLink:fullURL]; // get the imageID
	if (mediaID)
	{
		[self mediaDataWithID:mediaID success:^(id responseObject) { // get the mediaDict from the API
			NSDictionary *data = (NSDictionary *)responseObject[@"data"];
			TGMediaType type;
			NSDictionary *imageOrVideoDict;
			if ([data[@"type"] isEqualToString:@"video"])
			{
				imageOrVideoDict = data[@"videos"][@"standard_resolution"];
				type = TGMediaTypeVideo;
			}
			else
			{
				imageOrVideoDict = data[@"images"][@"standard_resolution"];
				type = TGMediaTypeImage;
			}
			
			TGMedia *media = [TGMedia new];
			media.type = type;
			media.url = [NSURL URLWithString:imageOrVideoDict[@"url"]];
			media.size = CGSizeMake([imageOrVideoDict[@"width"] floatValue], [imageOrVideoDict[@"height"] floatValue]);
			media.title = data[@"user"][@"username"];
			media.caption = data[@"caption"][@"text"];
			
			NSLog(@"media retrieved from instagram API: %@", media);
			
			success(@[media]);
		}];
	}
}

- (void) directMediaURLfromInstagramURL:(NSURL *)fullURL success:(void (^)(NSURL *mediaURL))success
{
	NSString *mediaID = [self mediaIDfromLink:fullURL]; // get the imageID
	if (mediaID)
	{
		[self mediaDataWithID:mediaID success:^(id responseObject) { // get the imageData from the API
			NSDictionary *data = (NSDictionary *)responseObject[@"data"];
			
			NSString *mediaURLstring = data[@"images"][@"standard_resolution"][@"url"]; // get default image link
			if ([data[@"type"] isEqualToString:@"video"]) mediaURLstring = data[@"videos"][@"standard_resolution"][@"url"]; // check if it's a video, if so, get mp4 link instead
			
			NSURL *mediaURL = [NSURL URLWithString:mediaURLstring];
			NSLog(@"directImageURL retrieved from instagram API: %@", mediaURL);
			success(mediaURL);
		}];
	}
}

- (void) mediaDataWithID:(NSString *)mediaID success:(void (^)(id responseObject))success
{
	NSString *url = [NSString stringWithFormat:@"%@media/shortcode/%@", self.baseURLString, mediaID];
	NSDictionary *parameters = @{ @"client_id": [self clientID] };
	
	[self GET:url
   parameters:parameters
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

- (BOOL) URLisInstagramLink:(NSURL *)url
{
	if ([url.host containsString:@"instagram.com"] && [url.path containsString:@"/p/"]) return YES;
	return NO;
}

#pragma mark - Convenience

- (NSString *) mediaIDfromLink:(NSURL *)url
{
	NSString *path = url.path;
	
	NSString *imageID = [path stringByReplacingOccurrencesOfString:@"/p/" withString:@""];
	if (path.length - imageID.length == 3)
		return [imageID stringByReplacingOccurrencesOfString:@"/" withString:@""];
	
	return nil;
}

@end
