//
//  TGInstagramClient.h
//  redditPad
//
//  Created by Tom Graham on 23/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGAPIClient.h"

@interface TGInstagramClient : TGAPIClient

#pragma mark - Media

- (void) mediaFromInstagramURL:(NSURL *)fullURL success:(void (^)(NSArray *media))success;
- (void) directMediaURLfromInstagramURL:(NSURL *)fullURL success:(void (^)(NSURL *mediaURL))success;

#pragma mark - Detecting Link Types

- (BOOL) URLisInstagramLink:(NSURL *)url;

#pragma mark - Convenience

- (NSString *) mediaIDfromLink:(NSURL *)url;

@end
