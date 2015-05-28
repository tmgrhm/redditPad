//
//  TGImgurClient.h
//  redditPad
//
//  Created by Tom Graham on 19/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TGAPIClient.h"

@interface TGImgurClient : TGAPIClient

#pragma mark - Media

- (void) mediaFromURL:(NSURL *)url success:(void (^)(NSArray *media))success;

#pragma mark - Image

- (void) directImageURLfromImgurURL:(NSURL *)fullURL success:(void (^)(NSURL *imageURL))success;

#pragma mark - Album

- (void) coverImageURLfromAlbumURL:(NSURL *)fullURL success:(void (^)(NSURL *coverImageURL))success;
- (void) albumMediaWithID:(NSString *)albumID success:(void (^)(NSArray *media))success;

#pragma mark - Detecting Link Types

- (BOOL) URLisImgurLink:(NSURL *)url;
- (BOOL) URLisSingleImageLink:(NSURL *)url;
- (BOOL) URLisAlbumLink:(NSURL *)url;

#pragma mark - Convenience

- (NSString *) imageIDfromLink:(NSURL *)url;
- (NSString *) albumIDfromLink:(NSURL *)url;

@end