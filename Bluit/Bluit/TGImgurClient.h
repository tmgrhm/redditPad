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

#pragma mark - Image

- (void) imageURLfromURL:(NSURL *)fullURL success:(void (^)(NSURL *imageURL))success;
- (void) imageDataFromURL:(NSURL *)url success:(void (^)(id responseObject))success;
- (void) imageDataWithID:(NSString *)imageID success:(void (^)(id responseObject))success;

#pragma mark - Album

- (void) coverImageURLfromAlbumURL:(NSURL *)fullURL success:(void (^)(NSURL *coverImageURL))success;
- (void) albumDataWithID:(NSString *)albumID success:(void (^)(id responseObject))success;

#pragma mark - Detecting Link Types

- (BOOL) URLisImgurLink:(NSURL *)url;
- (BOOL) URLisSingleImageLink:(NSURL *)url;
- (BOOL) URLisAlbumLink:(NSURL *)url;

#pragma mark - Convenience

- (NSString *) imageIDfromLink:(NSURL *)url;
- (NSString *) albumIDfromLink:(NSURL *)url;

@end