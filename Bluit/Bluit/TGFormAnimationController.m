//
//  TGFormAnimatedTransitioning.m
//  redditPad
//
//  Created by Tom Graham on 05/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGFormAnimationController.h"

@interface TGFormAnimationController()

@property (nonatomic) BOOL isPresenting;

@end

@implementation TGFormAnimationController

- (instancetype) initPresenting:(BOOL)isPresenting
{
	self = [super init];
	self.isPresenting = isPresenting;
	return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
	return kFormTransitionDuration;
}

- (void) animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
	if (self.isPresenting)	[self animatePresentation:transitionContext];
	else						[self animateDismissal:transitionContext];
}

- (void) animatePresentation:(id<UIViewControllerContextTransitioning>)transitionContext
{
	UIViewController *presentedVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	UIView *presentedView = [transitionContext viewForKey:UITransitionContextToViewKey];
	UIView *containerView = [transitionContext containerView];
	
	// position presentedVC offscreen
	presentedView.frame = [transitionContext finalFrameForViewController:presentedVC];
	presentedView.center = CGPointMake(presentedView.center.x, presentedView.center.y + containerView.bounds.size.height);
	
	[containerView addSubview:presentedView];
	
	[UIView animateWithDuration:kFormTransitionDuration delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
		presentedView.center = CGPointMake(presentedView.center.x, presentedView.center.y - containerView.bounds.size.height);
	} completion:^(BOOL finished) {
		[transitionContext completeTransition:finished];
	}];
}

- (void) animateDismissal:(id<UIViewControllerContextTransitioning>)transitionContext
{
	UIView *presentedView = [transitionContext viewForKey:UITransitionContextFromViewKey];
	UIView *containerView = [transitionContext containerView];

	[UIView animateWithDuration:kFormTransitionDuration delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
		presentedView.center = CGPointMake(presentedView.center.x, presentedView.center.y + containerView.bounds.size.height);
	} completion:^(BOOL finished) {
		[transitionContext completeTransition:finished];
	}];
}

@end
