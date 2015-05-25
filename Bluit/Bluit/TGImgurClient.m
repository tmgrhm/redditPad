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

- (void) directImageURLfromImgurURL:(NSURL *)fullURL success:(void (^)(NSURL *imageURL))success
{
	if ([self URLisSingleImageLink:fullURL]) // if link to single image
	{
		NSString *imageID = [self imageIDfromLink:fullURL]; // get the imageID
		if (imageID)
		{
			[self imageDataWithID:imageID success:^(id responseObject) { // get the imageData from the API
				NSDictionary *imageDict = (NSDictionary *)responseObject[@"data"];
				
				NSURL *directURL = [self directURLfromImageDictionary:imageDict];
				NSLog(@"directImageURL retrieved from imgur API: %@", directURL);
				success(directURL);
			}];
		}
	}
	else if ([self URLisAlbumLink:fullURL]) // if link to album
	{
		[self coverImageURLfromAlbumURL:fullURL success:success];
	}
	// TODO gallery link
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
			for (NSDictionary *imageDict in responseDict[@"data"][@"images"])
				if ([imageDict[@"id"] isEqualToString:coverImageID]) coverImageURL = [self directURLfromImageDictionary:imageDict];
			
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
	if ([url.host containsString:@"imgur.com"])
	{
		if ([self URLisAlbumLink:url]) return YES;
		if ([self URLisSingleImageLink:url]) return YES;
		// TODO /gallery/ links
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
	
	NSString *imageID = [path stringByReplacingOccurrencesOfString:@"/" withString:@""];
	if (path.length - imageID.length == 1)  // only one slash, suggests it should be a single image
	{
		// remove any file extensions
		NSString *pattern = @"\\..*";
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
		imageID = [regex stringByReplacingMatchesInString:imageID options:0 range:NSMakeRange(0, [imageID length]) withTemplate:@""];
		
		return imageID;
	}
	
	return nil;
}

- (NSString *) albumIDfromLink:(NSURL *)url
{
	NSString *path = url.path;
	
	NSString *albumCoverImageID = [path stringByReplacingOccurrencesOfString:@"/a/" withString:@""]; // album
	if (path.length - albumCoverImageID.length == 3) return albumCoverImageID;
	
	return nil;
}

- (NSURL *) directURLfromImageDictionary:(NSDictionary *)imageDict
{
	NSString *imageURLstring = imageDict[@"link"]; // get default image link
	if ([imageDict[@"animated"] boolValue] == YES && [@"image/gif" isEqualToString:imageDict[@"type"]]) imageURLstring = imageDict[@"mp4"]; // check if it's animated, if so, get mp4 link instead
	
	NSURL *directURL = [NSURL URLWithString:imageURLstring];
	return directURL;
}

@end
