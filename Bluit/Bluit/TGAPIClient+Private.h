//
//  TGAPIClient+Private.h
//  redditPad
//
//  Created by Tom Graham on 20/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGAPIClient.h"

@interface TGAPIClient () // private properties available to subclasses

@property (strong, nonatomic) AFHTTPRequestSerializer *serializer;
@property (strong, nonatomic) AFHTTPSessionManager *manager;

@property (strong, nonatomic) NSString *modhash;
@property (strong, nonatomic) NSString *sessionIdentifier;

@property (strong, nonatomic) NSString *accessToken;
@property (strong, nonatomic) NSString *refreshToken;
@property (strong, nonatomic) NSDate *currentTokenExpirationDate;
@property (nonatomic) BOOL isRefreshingToken;

@property (strong, nonatomic) NSString *baseURLString;

- (NSString *)valueForKey:(NSString *)key fromQueryItems:(NSArray *)queryItems;
- (BOOL) accessTokenHasExpired;

@end
