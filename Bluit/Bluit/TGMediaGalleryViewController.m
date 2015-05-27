//
//  TGMediaViewController.m
//  redditPad
//
//  Created by Tom Graham on 27/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGMediaGalleryViewController.h"

#import "ThemeManager.h"
#import "TGMediaView.h"

#import <AFNetworking/UIImageView+AFNetworking.h>
@import MediaPlayer;

@interface TGMediaGalleryViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate, UIDynamicAnimatorDelegate>

@property (strong, nonatomic) UIView *containerView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *fadeView;

@property (strong, nonatomic) NSMutableArray *media;
@property (strong, nonatomic) NSMutableArray *mediaViews;

@property (strong, nonatomic) UITapGestureRecognizer *tapRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (strong, nonatomic) UIDynamicAnimator *animator;

@property (nonatomic) CGPoint originalCenter;

@end

@implementation TGMediaGalleryViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
	
	[self themeAppearance];
	
	self.containerView = [[UIView alloc] initWithFrame:self.view.bounds];
	self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.scrollView addSubview:self.containerView];
	
	self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
	self.tapRecognizer.delegate = self;
	[self.containerView addGestureRecognizer:self.tapRecognizer];
	
	self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
	self.panRecognizer.delegate = self;
	[self.containerView addGestureRecognizer:self.panRecognizer];
	
	self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
//	self.animator.delegate = self;
	
	if (self.mediaURL) [self loadMediaFromURL:self.mediaURL]; // TODO
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) themeAppearance
{
	self.fadeView.backgroundColor = [ThemeManager colorForKey:kTGThemeDimmerColor];
	self.fadeView.alpha = 0.5f;
	
	
	self.scrollView.showsHorizontalScrollIndicator = YES;
	self.scrollView.showsVerticalScrollIndicator = YES;
}

- (void) loadMediaFromURL:(NSURL *)url
{
	self.mediaURL = url;
	
	// TODO
	
	TGMediaView *mediaView = [[TGMediaView alloc] initWithFrame:self.containerView.frame];
	mediaView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[mediaView loadMediaFromURL:self.mediaURL];
	[self.containerView addSubview:mediaView];
}

#pragma mark - UIGestureRecognizer

- (IBAction) handlePan:(UIPanGestureRecognizer *)gesture
{
	// http://stackoverflow.com/a/21346822
	
	static UIAttachmentBehavior *attachment;
	// variables for calculating angular velocity
	static CFAbsoluteTime        lastTime;
	static CGFloat               lastAngle;
	static CGFloat               angularVelocity;
	
	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		[self.animator removeAllBehaviors];
		
		self.originalCenter = gesture.view.center; // TODO
		
		// calculate the center offset and anchor point
		CGPoint pointWithinAnimatedView = [gesture locationInView:gesture.view];
		
		UIOffset offset = UIOffsetMake(pointWithinAnimatedView.x - gesture.view.bounds.size.width / 2.0,
									   pointWithinAnimatedView.y - gesture.view.bounds.size.height / 2.0);
		
		CGPoint anchor = [gesture locationInView:gesture.view.superview];
		
		// create attachment behavior
		attachment = [[UIAttachmentBehavior alloc] initWithItem:gesture.view
											   offsetFromCenter:offset
											   attachedToAnchor:anchor];
		
		// calculate angular velocity
		lastTime = CFAbsoluteTimeGetCurrent();
		lastAngle = [self angleOfView:gesture.view];
		
		typeof(self) __weak weakSelf = self;
		attachment.action = ^{
			CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
			CGFloat angle = [weakSelf angleOfView:gesture.view];
			if (time > lastTime)
			{
				angularVelocity = (angle - lastAngle) / (time - lastTime);
				lastTime = time;
				lastAngle = angle;
			}
		};
		
		// add attachment behavior
		[self.animator addBehavior:attachment];
	}
	else if (gesture.state == UIGestureRecognizerStateChanged)
	{
		// as user makes gesture, update attachment behavior's anchor point, achieving drag 'n' rotate
		CGPoint anchor = [gesture locationInView:gesture.view.superview];
		attachment.anchorPoint = anchor;
	}
	else if (gesture.state == UIGestureRecognizerStateEnded)
	{
		[self.animator removeAllBehaviors];
		
		CGPoint velocity = [gesture velocityInView:gesture.view.superview];
		CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
		// if magnitude is low, snap back to original position and return
		if (magnitude < 2000)
		{
			UISnapBehavior *snap = [[UISnapBehavior alloc] initWithItem:gesture.view snapToPoint:self.originalCenter];
			snap.damping = 0.5f;
			[self.animator addBehavior:snap];
			return;
		}
		// otherwise, create UIDynamicItemBehavior that carries on animation from where the gesture left off (notably linear and angular velocity)
		UIDynamicItemBehavior *dynamic = [[UIDynamicItemBehavior alloc] initWithItems:@[gesture.view]];
		[dynamic addLinearVelocity:velocity forItem:gesture.view];
		[dynamic addAngularVelocity:angularVelocity forItem:gesture.view];
		
		dynamic.angularResistance = 1.25f;
		dynamic.density = 2.0f;
		dynamic.resistance = -1.0f;
		
		// when the view no longer intersects with its superview, go ahead and remove it
		typeof(self) __weak weakSelf = self;
		dynamic.action = ^{
			// TODO fade dimmingView alpha based on progress from centrepoint to exitpoint
			if (!CGRectIntersectsRect(gesture.view.superview.bounds, gesture.view.frame))
			{
				[weakSelf.animator removeAllBehaviors];
				[gesture.view removeFromSuperview];
				
				[self dismissViewControllerAnimated:YES completion:nil];
			}
		};
		
		[self.animator addBehavior:dynamic];
		
		// add a little gravity so it accelerates off the screen (in case user gesture was slow)
		//		UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[gesture.view]];
		//		gravity.magnitude = 1.0;
		//		[self.animator addBehavior:gravity];
		
		// TODO replace gravity with attachment behaviour at angle of pan to increase velocity
	}
}

- (void) enablePanGesture:(BOOL)enabled
{
	if (enabled)		[self.containerView addGestureRecognizer:self.panRecognizer];
	else				[self.containerView removeGestureRecognizer:self.panRecognizer];
}

- (void) handleTap:(UITapGestureRecognizer *)tapRecognizer
{
	// TODO
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

/*- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	// TODO
	CGFloat transformScale = self.imageView.transform.a;
	BOOL shouldRecognize = transformScale > _minScale;
	
	return shouldRecognize;
}*/

#pragma mark - Convenience

- (CGFloat)angleOfView:(UIView *)view
{
	// http://stackoverflow.com/a/2051861/1271826
	
	return atan2(view.transform.b, view.transform.a);
}


@end
