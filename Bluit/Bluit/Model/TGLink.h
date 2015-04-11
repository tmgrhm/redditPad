//
//  TGLink.h
//  redditPad
//
//  Created by Tom Graham on 10/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGVotable.h"

@interface TGLink : TGVotable

// TODO flair
// TODO reported
// TODO vote ratio

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, assign, readonly) NSUInteger totalComments;
@property (nonatomic, copy, readonly) NSString *subreddit;
@property (nonatomic, copy, readonly) NSString *domain;
@property (nonatomic, copy, readonly) NSURL *url;
@property (nonatomic, copy, readonly) NSString *author;
@property (nonatomic, copy, readonly) NSString *selfText;
@property (nonatomic, copy, readonly) NSString *selfTextHTML;
@property (nonatomic, copy, readonly) NSURL *thumbnailURL;
@property (nonatomic, assign, readonly, getter=isEdited) BOOL edited;
@property (nonatomic, copy, readonly) NSDate *editDate;
@property (nonatomic, assign, readonly, getter=isSelfpost) BOOL selfpost;
@property (nonatomic, assign, readonly, getter=isHidden) BOOL hidden;
@property (nonatomic, assign, readonly, getter=isSaved) BOOL saved;
@property (nonatomic, assign, readonly, getter=isNSFW) BOOL nsfw;
@property (nonatomic, assign, readonly, getter=isSticky) BOOL sticky;
@property (nonatomic, assign, readonly, getter=isViewed) BOOL viewed; // TODO set when viewed

@property (nonatomic, copy, readonly) NSURL *permalink;

- (instancetype) initLinkFromDictionary:(NSDictionary *)dict;

@end