//
//  TGRedditClient.h
//  redditPad
//
//  Created by Tom Graham on 03/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TGLink;

typedef void (^TGListingCompletionBlock)(NSArray *collection, NSError *error); // TODO move

@interface TGRedditClient : NSObject

+ (instancetype)sharedClient;

- (void) requestFrontPageWithCompletionBlock:(TGListingCompletionBlock)block;
- (void) requestSubreddit:(NSString *)subredditURL withCompletion:(TGListingCompletionBlock)completion;
- (void) requestSubreddit:(NSString *)subredditURL after:(TGLink *)link withCompletion:(TGListingCompletionBlock)completion;

- (void) request:(NSString *)request withCompletionBlock:(TGListingCompletionBlock)block;

- (void) loginWithUsername:(NSString *)username password:(NSString *)password withCompletion:(void (^)(void))completion;
- (NSURL *) oAuthLoginURL;
- (void) loginWithOAuthResponse:(NSURL *)url;

- (void) setSerializerHTTPHeaders:(NSString *)modhash and:(NSString *)sessionIdentifier;

- (void) retrieveUserSubscriptionsWithCompletion:(void (^)(NSArray *subreddits))completion;

- (void) requestCommentsForLink:(TGLink *)link withCompletion:(void (^)(NSArray* comments))completion;


@end
