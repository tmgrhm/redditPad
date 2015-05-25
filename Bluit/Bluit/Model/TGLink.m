//
//  TGLink.m
//  redditPad
//
//  Created by Tom Graham on 10/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGLink.h"

#import "TGImgurClient.h"
#import "TGTwitterClient.h"
#import "TGGfycatClient.h"
#import "TGInstagramClient.h"
#import "TGVineClient.h"

#import <MWFeedParser/NSString+HTML.h>

@implementation TGLink

- (instancetype) initLinkFromDictionary:(NSDictionary *)dict
{
	self = [super initFromDictionary:dict];
	if (!self) {
		return nil;
	}
	
	NSDictionary *data = dict[@"data"];
	
	_title =				[data[@"title"] stringByDecodingHTMLEntities];
	_totalComments =	[data[@"num_comments"] unsignedIntegerValue];
	_subreddit =			data[@"subreddit"];
	_author =			data[@"author"];
	_domain =			data[@"domain"];
	_url =				[NSURL URLWithString:data[@"url"]];
	_edited =			[data[@"edited"] boolValue];
	_editDate =			_edited ? [NSDate dateWithTimeIntervalSince1970:[data[@"edited"] unsignedIntegerValue]] : nil;
	_selfpost =			[data[@"is_self"] boolValue];
	_hidden =			[data[@"hidden"] boolValue];
	_nsfw =				[data[@"over_18"] boolValue];
	_sticky =			[data[@"stickied"] boolValue];
	_viewed =			[data[@"visited"] boolValue];
	
	NSString *selfText = data[@"selftext"];
	if (selfText)
	{
		selfText = [selfText stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
		selfText = [selfText stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
		selfText = [selfText stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
	}
	_selfText =		data[@"selftext"];
	_selfTextHTML =	data[@"selftext_html"] == [NSNull null] ? @"" : [data[@"selftext_html"] stringByDecodingHTMLEntities];
	
	_embeddedMediaType = EmbeddedMediaUnknown;
	
	_thumbnailURL = _selfpost ? nil : [NSURL URLWithString:data[@"thumbnail"]];
	
	return self;
}

- (TGLinkEmbeddedMediaType) embeddedMediaType
{
	if (_embeddedMediaType == EmbeddedMediaUnknown) _embeddedMediaType = [self findEmbeddedMediaType]; // lazy check
	
	return _embeddedMediaType;
}

- (TGLinkEmbeddedMediaType) findEmbeddedMediaType
{
	TGLinkEmbeddedMediaType type = EmbeddedMediaNone;
	
	if (self.isImageLink)														type = EmbeddedMediaDirectImage;
	else if ([[TGImgurClient sharedClient] URLisImgurLink:self.url])			type = EmbeddedMediaImgur;
	else if ([[TGTwitterClient sharedClient] URLisTwitterLink:self.url])		type = EmbeddedMediaTweet;
	else if ([[TGGfycatClient sharedClient] URLisGfycatLink:self.url])			type = EmbeddedMediaGfycat;
	else if ([[TGInstagramClient sharedClient] URLisInstagramLink:self.url])	type = EmbeddedMediaInstagram;
	else if ([[TGVineClient sharedClient] URLisVineLink:self.url])				type = EmbeddedMediaVine;
	
	return type;
}

- (BOOL) isRichLink
{
	if (self.embeddedMediaType != EmbeddedMediaNone) return YES; // cheap check after first use
	else return NO;
}

- (BOOL) isImageLink
{
	BOOL isImageLink;
	
	if (_embeddedMediaType == EmbeddedMediaUnknown)
	{
		NSString *urlFileExtension = _url.lastPathComponent.pathExtension;
		isImageLink = [urlFileExtension isEqualToString:@"png"] || [urlFileExtension isEqualToString:@"jpg"] || [urlFileExtension isEqualToString:@"jpeg"];
	}
	else if (_embeddedMediaType == EmbeddedMediaDirectImage) isImageLink = YES;
	
	return isImageLink;
}

- (BOOL) isMediaLink
{
	switch (self.embeddedMediaType) {
		case EmbeddedMediaDirectImage:
		case EmbeddedMediaDirectVideo:
		case EmbeddedMediaImgur:
		case EmbeddedMediaInstagram:
		case EmbeddedMediaTweetWithImage:
		case EmbeddedMediaGfycat:
		case EmbeddedMediaVine:
			return YES;
			break;
		default:
			return NO;
			break;
	}
}

- (void) requestDirectURLforEmbeddedMediaWithSuccess:(void (^)(NSURL *mediaURL))success
{
	switch (self.embeddedMediaType)
	{
		case EmbeddedMediaDirectImage:
		{
			success(self.url);
			break;
		}
		case EmbeddedMediaImgur:
		{
			[[TGImgurClient sharedClient] directImageURLfromImgurURL:self.url success:success];
			break;
		}
		case EmbeddedMediaTweet:
		{
			[[TGTwitterClient sharedClient] tweetWithID:[[TGTwitterClient sharedClient] tweetIDfromLink:self.url] success:^(id responseObject) {
				self.embeddedMediaData = (NSDictionary *) responseObject;

				if (self.embeddedMediaData[@"entities"][@"media"][0])
				{
					self.embeddedMediaType = EmbeddedMediaTweetWithImage;
					
					NSURL *imageURL = [NSURL URLWithString:[self.embeddedMediaData[@"entities"][@"media"][0][@"media_url_https"] stringByAppendingString:@":large"]]; // get large variant
					
					success(imageURL);
				}
				success(nil);
			}];
			break;
		}
		case EmbeddedMediaGfycat:
		{
			[[TGGfycatClient sharedClient] mp4URLfromGfycatURL:self.url success:success];
			break;
		}
		case EmbeddedMediaInstagram:
		{
			[[TGInstagramClient sharedClient] directMediaURLfromInstagramURL:self.url success:success];
			break;
		}
		case EmbeddedMediaVine:
		{
			[[TGVineClient sharedClient] mp4URLfromVineURL:self.url success:success];
			break;
		}
		default:
		{
			NSLog(@"I shouldn't be here…"); // TODO doublecheck
			success(nil);
		}
	}
}

@end