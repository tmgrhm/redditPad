//
//  TGAPIClient.h
//  redditPad
//
//  Created by Tom Graham on 19/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AFNetworking/AFHTTPRequestOperation.h>
#import <AFNetworking/AFHTTPSessionManager.h>

static NSString * const kBaseURLString;
static NSString * const kBaseHTTPSURLString;
static NSString * const client_id;

static NSString * const kURIscheme = @"redditpad";
static NSString * const kURIRedirectPath;
static NSString * const oAuthState;


@interface TGAPIClient : NSObject

+ (instancetype) sharedClient;

#pragma mark - Values

- (NSString *) standardBaseURLString;
- (NSString *) httpsBaseURLString;
- (NSString *) clientID;

- (NSString *) uriScheme;
- (NSString *) uriRedirectPath;
- (NSString *) oAuthState;

#pragma mark - Convenience

- (void) POST:(NSString *)stringURL parameters:(NSDictionary *)parameters success:(void (^)(NSURLSessionDataTask* task, id responseObject))success failure:(void (^)(NSURLSessionDataTask* task, NSError* error))failure;
- (void) GET:(NSString *)stringURL parameters:(NSDictionary *)parameters success:(void (^)(NSURLSessionDataTask* task, id responseObject))success failure:(void (^)(NSURLSessionDataTask* task, NSError* error))failure;
- (void) failureWithError:(NSError *)error;

@end