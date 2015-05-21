//
//  TGImgurClient.m
//  redditPad
//
//  Created by Tom Graham on 19/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGImgurClient.h"

#import "TGAPIClient+Private.h"

static NSString * const kBaseURLString = @"http://www.imgur.com/";
static NSString * const kBaseHTTPSURLString = @"https://api.imgur.com/3/";

// OAuth parameters
static NSString * const client_id = @"05e19e4035fa24f";
static NSString * const oAuthState = nil;
static NSString * const kURIRedirectPath = nil;

@implementation TGImgurClient

+ (instancetype) sharedClient
{
	static TGImgurClient *sharedClient = nil;
	static dispatch_once_t oncePredicate;
	dispatch_once(&oncePredicate, ^{
		sharedClient = [TGImgurClient new];
	});
	
	return sharedClient;
}

- (instancetype) init
{
	self = [super init];
	if (self)
	{
		[self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Client-ID %@", [self clientID]] forHTTPHeaderField:@"Authorization"];
		
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

#pragma mark - Image

- (void) imageURLfromURL:(NSURL *)fullURL success:(void (^)(NSURL *imageURL))success
{
	if ([self URLisSingleImageLink:fullURL])
	{
		NSString *imageID = [self imageIDfromLink:fullURL];
		if (imageID)
		{
			[self imageDataWithID:imageID success:^(id responseObject) {
				NSDictionary *responseDict = (NSDictionary *)responseObject;
				
				NSURL *imageURL = [NSURL URLWithString:responseDict[@"data"][@"link"]]; // TODO
				NSLog(@"imageURL %@", imageURL);
				success(imageURL);
			}];
		}
	}
	else if ([self URLisAlbumLink:fullURL])
	{
		[self coverImageURLfromAlbumURL:fullURL success:success];
	}
}

- (void) imageDataFromURL:(NSURL *)url success:(void (^)(id responseObject))success
{
	NSString *path = url.path;
	NSString *imageID = [path stringByReplacingOccurrencesOfString:@"/" withString:@""];
	NSInteger numSlashes = [path length] - [imageID length];
	
	if (numSlashes == 1) [self imageDataWithID:imageID success:success];
	else if ([path hasPrefix:@"/a/"]) [self albumDataWithID:[self albumIDfromLink:url] success:success];
}

- (void) imageDataWithID:(NSString *)imageID success:(void (^)(id responseObject))success
{
	NSString *url = [NSString stringWithFormat:@"%@image/%@", self.baseURLString, imageID];
	
	[self GET:url
	parameters:nil
	   success:^(NSURLSessionDataTask *task, id responseObject) {
		// TODO
//		NSLog(@"%@", responseObject);
		success(responseObject);
	}
	   failure:^(NSURLSessionDataTask *task, NSError *error) {
		// TODO
		[self failureWithError:error];
	}];
}

#pragma mark - Album

- (void) coverImageURLfromAlbumURL:(NSURL *)fullURL success:(void (^)(NSURL *coverImageURL))success
{
	NSString *albumID = [self albumIDfromLink:fullURL];
	if (albumID)
	{
		[self albumDataWithID:albumID success:^(id responseObject) {
			NSDictionary *responseDict = (NSDictionary *)responseObject;
			// get coverImageID and use that to get coverImageURL
			NSString *coverImageID = responseDict[@"data"][@"cover"];
			NSURL *coverImageURL;
			for (id image in responseDict[@"data"][@"images"])
				if ([image[@"id"] isEqualToString:coverImageID])
					coverImageURL = [NSURL URLWithString:image[@"link"]];
			
			NSLog(@"coverImageURL %@", coverImageURL);
			success(coverImageURL);
		}];
	}
}

- (void) albumDataWithID:(NSString *)albumID success:(void (^)(id responseObject))success
{
	NSString *url = [NSString stringWithFormat:@"%@album/%@", self.baseURLString, albumID];
	
	[self GET:url
   parameters:nil
	  success:^(NSURLSessionDataTask *task, id responseObject) {
		  // TODO
//		  NSLog(@"album\n%@", responseObject);
		  success(responseObject);
	  }
	  failure:^(NSURLSessionDataTask *task, NSError *error) {
		  // TODO
		  [self failureWithError:error];
	  }];
}

#pragma mark - Detecting Link Types

- (BOOL) URLisImgurLink:(NSURL *)url
{
	if ([url.host isEqualToString:@"imgur.com"])
	{
		if ([self URLisAlbumLink:url]) return YES;
		if ([self URLisSingleImageLink:url]) return YES;
	}
	
	return NO;
}

- (BOOL) URLisSingleImageLink:(NSURL *)url
{
	NSString *path = url.path;
	NSInteger numSlashes = [path length] - [[path stringByReplacingOccurrencesOfString:@"/" withString:@""] length];
	
	if (numSlashes == 1) return YES;
	else return NO;
}

- (BOOL) URLisAlbumLink:(NSURL *)url
{
	NSString *path = url.path;
	
	if ([path hasPrefix:@"/a/"]) return YES;
	else return NO;
}

#pragma mark - Convenience

- (NSString *) imageIDfromLink:(NSURL *)url
{
	NSString *path = url.path;
	
	NSString *imageID = [path stringByReplacingOccurrencesOfString:@"/" withString:@""]; // single image
	if (path.length - imageID.length == 1) return imageID;
	
	return nil;
}

- (NSString *) albumIDfromLink:(NSURL *)url
{
	NSString *path = url.path;
	
	NSString *albumCoverImageID = [path stringByReplacingOccurrencesOfString:@"/a/" withString:@""]; // album
	if (path.length - albumCoverImageID.length == 3) return albumCoverImageID;
	
	return nil;
}

@end
