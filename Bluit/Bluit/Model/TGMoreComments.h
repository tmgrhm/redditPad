//
//  TGMoreComments.h
//  redditPad
//
//  Created by Tom Graham on 10/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGThing.h"

@interface TGMoreComments : TGThing

@property (nonatomic, strong, readonly) NSArray *childrenIDs;
@property (nonatomic, assign, readonly) NSInteger numChildren;
@property (nonatomic, copy, readonly) NSString *parentID;

- (instancetype) initFromDictionary:(NSDictionary *)dict;

@end
