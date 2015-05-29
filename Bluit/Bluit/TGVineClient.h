//
//  TGVineClient.h
//  redditPad
//
//  Created by Tom Graham on 24/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGAPIClient.h"

@interface TGVineClient : TGAPIClient

#pragma mark - Image

- (void) mediaFromVineURL:(NSURL *)url success:(void (^)(NSArray *media))success;
- (void) mp4URLfromVineURL:(NSURL *)fullURL success:(void (^)(NSURL *vineURL))success;

#pragma mark - Detecting Link Types

- (BOOL) URLisVineLink:(NSURL *)url;

#pragma mark - Convenience

- (NSString *) vineIDfromLink:(NSURL *)url;

@end
