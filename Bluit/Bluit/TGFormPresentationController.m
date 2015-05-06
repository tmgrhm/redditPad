//
//  TGFormPresentationController.m
//  redditPad
//
//  Created by Tom Graham on 05/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGFormPresentationController.h"

#import "ThemeManager.h"

@interface TGFormPresentationController()

@property (strong, nonatomic) UIView *dimmingView;

@end

@implementation TGFormPresentationController

- (UIView *) dimmingView
{
	if (!_dimmingView)
	{
		UIButton *dim = [UIButton new];
		dim.frame = self.containerView.bounds;
		dim.alpha = 0.0;
		dim.backgroundColor = [ThemeManager shadeColor];
		[dim setTitle:@"" forState:UIControlStateNormal];
		[dim addTarget:self action:@selector(didTapOutsidePresentedView:) forControlEvents:UIControlEventTouchUpInside];
		_dimmingView = dim;
	}
	return _dimmingView;
}

#pragma mark - IBActions

- (void) didTapOutsidePresentedView:(id)sender
{
	[self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Presentation Controller

- (void) presentationTransitionWillBegin
{
	// add dim + presented views to hierarchy
	[self.containerView addSubview:self.dimmingView];
	[self.containerView addSubview:self.presentedView];
	// fade in dim alongside other animations
	[self.presentingViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		self.dimmingView.alpha = 0.7;
	} completion:nil];
}

- (void) presentationTransitionDidEnd:(BOOL)completed
{
	// If the presentation didn't complete, remove the dimming view
	if (!completed) [self.dimmingView removeFromSuperview];
}

- (void) dismissalTransitionWillBegin
{
	// fade out dim alongside other animations
	[self.presentingViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		self.dimmingView.alpha = 0.0;
	} completion:nil];
}

- (void) dismissalTransitionDidEnd:(BOOL)completed
{
	// if dismissed, remove dimming view
	if (completed) [self.dimmingView removeFromSuperview];
}

- (CGRect) frameOfPresentedViewInContainerView
{
	CGSize presentedVCSize = self.presentedViewController.preferredContentSize;
	CGRect frame = self.containerView.frame;
	float widthDiff = frame.size.width - presentedVCSize.width;
	float heightDiff = frame.size.height - presentedVCSize.height;
	
	return CGRectInset(frame, widthDiff/2, heightDiff/2);
}

@end
