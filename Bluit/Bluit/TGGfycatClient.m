//
//  TGGfycatClient.m
//  redditPad
//
//  Created by Tom Graham on 23/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGGfycatClient.h"

#import "TGAPIClient+Private.h"

#import "TGMedia.h"

static NSString * const kBaseURLString = @"http://gfycat.com/";
static NSString * const kBaseHTTPSURLString = nil;

@implementation TGGfycatClient

+ (instancetype) sharedClient
{
	static TGGfycatClient *sharedClient = nil;
	static dispatch_once_t oncePredicate;
	dispatch_once(&oncePredicate, ^{
		sharedClient = [TGGfycatClient new];
	});
	
	return sharedClient;
}

- (instancetype) init
{
	self = [super init];
	if (self)
	{
		self.baseURLString = [self standardBaseURLString];
	}
	return self;
}

#pragma mark - Values

- (NSString *) standardBaseURLString {
	return kBaseURLString;
}

#pragma mark - Gfy

- (void) mediaFromURL:(NSURL *)url success:(void (^)(NSArray *media))success
{
	NSString *gfyID = [self gfyIDfromLink:url]; // get the gfyID
	if (gfyID)
	{
		[self gfyDataWithID:gfyID success:^(id responseObject) { // get the dict from the API
			NSDictionary *data = (NSDictionary *)responseObject[@"gfyItem"];
			
			TGMedia *media = [TGMedia new];
			media.type = TGMediaTypeVideo;
			media.url = [NSURL URLWithString:data[@"mp4Url"]]; // TODO get smaller version if wider than 668?
			media.title = data[@"title"];
			media.size = CGSizeMake([data[@"width"] floatValue], [data[@"height"] floatValue]);
			success(@[media]);
		}];
	}
}

- (void) mp4URLfromGfycatURL:(NSURL *)fullURL success:(void (^)(NSURL *mp4URL))success
{
	NSString *gfyID = [self gfyIDfromLink:fullURL]; // get the gfyID
	if (gfyID)
	{
		[self gfyDataWithID:gfyID success:^(id responseObject) { // get the imageData from the API
			NSDictionary *data = (NSDictionary *)responseObject[@"gfyItem"];
			
			NSString *mp4URLstring = data[@"mp4Url"]; // TODO get smaller version if wider than 668?
			NSURL *mp4URL = [NSURL URLWithString:mp4URLstring];
			success(mp4URL);
		}];
	}
}

- (void) gfyDataWithID:(NSString *)gfyID success:(void (^)(id responseObject))success
{
	NSString *url = [NSString stringWithFormat:@"%@cajax/get/%@", self.baseURLString, gfyID];
	
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

- (BOOL) URLisGfycatLink:(NSURL *)url
{
	if ([url.host containsString:@"gfycat.com"]) return YES;
	
	return NO;
}

#pragma mark - Convenience

- (NSString *) gfyIDfromLink:(NSURL *)url
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

@end
