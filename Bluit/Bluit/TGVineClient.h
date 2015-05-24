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

- (void) mp4URLfromVineURL:(NSURL *)fullURL success:(void (^)(NSURL *vineURL))success;
- (void) vineDataWithID:(NSString *)vineID success:(void (^)(id responseObject))success;

#pragma mark - Detecting Link Types

- (BOOL) URLisVineLink:(NSURL *)url;

#pragma mark - Convenience

- (NSString *) vineIDfromLink:(NSURL *)url;

@end
