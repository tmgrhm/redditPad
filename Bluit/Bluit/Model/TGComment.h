//
//  TGComment.h
//  redditPad
//
//  Created by Tom Graham on 13/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TGComment : NSObject

@property (nonatomic, copy, readonly) NSString *id;
@property (nonatomic, copy, readonly) NSString *body;
@property (nonatomic, copy, readonly) NSString *bodyHTML;
@property (nonatomic, assign, readonly) NSUInteger score;
@property (nonatomic, assign, readonly, getter=isScoreHidden) BOOL scoreHidden;
@property (nonatomic, copy, readonly) NSString *author;
@property (nonatomic, copy, readonly) NSDate *creationDate;
@property (nonatomic, assign, readonly, getter=isEdited) BOOL edited;
@property (nonatomic, copy, readonly) NSDate *editDate;
@property (nonatomic, assign, readonly, getter=isSaved) BOOL saved;

@property (nonatomic, strong) NSArray *children;
@property (nonatomic, assign) NSInteger indentationLevel;

+ (NSArray *) childrenRecursivelyForComment:(TGComment *)comment;

- (instancetype) initCommentFromDictionary:(NSDictionary *)dict;

- (NSUInteger) numReplies;

@end
