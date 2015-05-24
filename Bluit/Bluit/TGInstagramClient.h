//
//  TGInstagramClient.h
//  redditPad
//
//  Created by Tom Graham on 23/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGAPIClient.h"

@interface TGInstagramClient : TGAPIClient

#pragma mark - Image

- (void) directMediaURLfromInstagramURL:(NSURL *)fullURL success:(void (^)(NSURL *mediaURL))success;
- (void) mediaDataWithID:(NSString *)mediaID success:(void (^)(id responseObject))success;

#pragma mark - Detecting Link Types

- (BOOL) URLisInstagramLink:(NSURL *)url;

#pragma mark - Convenience

- (NSString *) mediaIDfromLink:(NSURL *)url;

@end
