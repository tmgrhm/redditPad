//
//  TGFormAnimatedTransitioning.h
//  redditPad
//
//  Created by Tom Graham on 05/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

static double const kFormTransitionDuration = 0.5;

@interface TGFormAnimationController : NSObject <UIViewControllerAnimatedTransitioning>

- (instancetype) initPresenting:(BOOL)isPresenting;

@end
