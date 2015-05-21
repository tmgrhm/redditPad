//
//  TGTwitterClient.h
//  redditPad
//
//  Created by Tom Graham on 20/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGAPIClient.h"

@interface TGTwitterClient : TGAPIClient

#pragma mark - Tweet

- (void) tweetWithID:(NSString *)tweetID success:(void (^)(id responseObject))success;

#pragma mark - Detecting Link Types

- (BOOL) URLisTwitterLink:(NSURL *)url;

#pragma mark - Covenenience

- (NSString *) tweetIDfromLink:(NSURL *)url;

@end
