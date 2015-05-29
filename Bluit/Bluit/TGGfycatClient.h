//
//  TGGfycatClient.h
//  redditPad
//
//  Created by Tom Graham on 23/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGAPIClient.h"

@interface TGGfycatClient : TGAPIClient

#pragma mark - Gfy

- (void) mediaFromURL:(NSURL *)url success:(void (^)(NSArray *media))success;
- (void) mp4URLfromGfycatURL:(NSURL *)fullURL success:(void (^)(NSURL *mp4URL))success;

#pragma mark - Detecting Link Types

- (BOOL) URLisGfycatLink:(NSURL *)url;

#pragma mark - Convenience

- (NSString *) gfyIDfromLink:(NSURL *)url;

@end
