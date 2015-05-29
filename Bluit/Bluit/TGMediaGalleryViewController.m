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
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@property (strong, nonatomic) NSMutableArray *mediaViews; // TGMediaViews or NSNull nulls if not yet loaded

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
	
	self.scrollView.delegate = self;
	
	self.containerView = [[UIView alloc] initWithFrame:self.scrollView.bounds];
	self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.scrollView addSubview:self.containerView];
	
	self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
	self.tapRecognizer.delegate = self;
	[self.scrollView addGestureRecognizer:self.tapRecognizer];
	
	self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
//	self.animator.delegate = self;
}

- (void) viewWillAppear:(BOOL)animated
{
	[self loadMedia];
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Getters & Setters

- (void) setMedia:(NSArray *)media
{
	// load mediaViews if they're not already & self is visible
	if (_media == nil && [self isViewLoaded])
	{
		_media = media;
		[self loadMedia];
	}
	else _media = media;
}

#pragma mark - Appearance

- (void) themeAppearance
{
	self.fadeView.backgroundColor = [ThemeManager colorForKey:kTGThemeDimmerColor];
	self.fadeView.alpha = 0.85f;
	
	self.scrollView.showsHorizontalScrollIndicator = NO;
	self.scrollView.showsVerticalScrollIndicator = NO;
	
	// TODO pagecontrol, scrollview scrollindicators style
}

#pragma mark - Loading

- (void) loadMedia
{
	NSArray *media = self.media;
	
	if (media.count == 1)	[self.pageControl removeFromSuperview]; // don't want pagecontrol if only one photo
	else						self.pageControl.numberOfPages = media.count;
	
	self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * media.count,
											 self.scrollView.frame.size.height);
	
	CGRect containerFrame = self.containerView.frame;
	containerFrame = CGRectMake(containerFrame.origin.x, containerFrame.origin.y, self.scrollView.contentSize.width, self.scrollView.contentSize.height);
	self.containerView.frame = containerFrame;
	
	self.mediaViews = [NSMutableArray new];
	for (NSInteger i = 0; i < media.count; ++i) [self.mediaViews addObject:[NSNull null]]; // add placeholders for views
	
	[self loadVisiblePages];
}

#pragma mark - Paged UIScrollView

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self loadVisiblePages];
}

- (void) loadVisiblePages
{
	// determine which page is currently visible
	CGFloat pageWidth = self.scrollView.frame.size.width;
	NSInteger page = (NSInteger)floor((self.scrollView.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
	
	self.pageControl.currentPage = page; // update the page control
	
	// Work out which pages you want to load
	NSInteger firstPage = page - 1;
	NSInteger lastPage = page + 1;
	
	// purge anything before the first page & after the last page
	for (NSInteger i=0; i < firstPage; i++) [self purgePage:i];
	for (NSInteger i=lastPage+1; i < self.media.count; i++) [self purgePage:i];
	// load pages in visible range
	for (NSInteger i=firstPage; i <= lastPage; i++) [self loadPage:i];
}

- (void) loadPage:(NSInteger)page
{
	if (page < 0 || page >= self.media.count) return; // If it's outside the range of what you have to display, then do nothing
	
	if ((NSNull *)[self.mediaViews objectAtIndex:page] == [NSNull null]) // view not loaded, load it
	{
		// calculate frame
		CGRect frame = self.scrollView.bounds;
		frame.origin.x = frame.size.width * page;
		frame.origin.y = 0.0f;
		frame = CGRectInset(frame, 10.0f, 0.0f);
		
		// create & configure mediaView
		TGMediaView *mediaView = [[TGMediaView alloc] initWithFrame:frame];
		mediaView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		mediaView.clipsToBounds = NO;
		TGMedia *media = [self.media objectAtIndex:page];
		[mediaView loadMediaFromURL:media.url];
		mediaView.title = ((NSNull *)media.title == [NSNull null]) ? @"" : media.title;
		mediaView.caption = ((NSNull *)media.caption == [NSNull null]) ? @"" : media.caption;
		
		// add gesture recognizers
		if (self.media.count == 1) // TODO
		{
			UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
			panRecognizer.delegate = self;
			[mediaView addGestureRecognizer:panRecognizer];
		}
		
		UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
		tapRecognizer.delegate = self;
		[mediaView addGestureRecognizer:tapRecognizer];
		
		[self.containerView addSubview:mediaView]; // add to scrollView
		
		[self.mediaViews replaceObjectAtIndex:page withObject:mediaView]; // replace null with loaded view
	}
}

- (void) purgePage:(NSInteger)page
{
	if (page < 0 || page >= self.media.count) return; // If it's outside the range of what you have to display, then do nothing
	
	TGMediaView *mediaView = [self.mediaViews objectAtIndex:page];
	if ((NSNull *)mediaView != [NSNull null])
	{
		// not null, remove from scrollView and null the view in the cache
		[mediaView removeFromSuperview];
		[self.mediaViews replaceObjectAtIndex:page withObject:[NSNull null]];
	}
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
	static CGPoint               originalCenter;
	
	CGPoint anchorPoint = [gesture locationInView:self.view];
	
	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		[self.animator removeAllBehaviors];
		
		originalCenter = gesture.view.center;
		
		// calculate the center offset and anchor point
		CGPoint pointWithinAnimatedView = [gesture locationInView:gesture.view];
		
		UIOffset offset = UIOffsetMake(pointWithinAnimatedView.x - gesture.view.bounds.size.width / 2.0,
									   pointWithinAnimatedView.y - gesture.view.bounds.size.height / 2.0);
		
		// create attachment behavior
		attachment = [[UIAttachmentBehavior alloc] initWithItem:gesture.view
											   offsetFromCenter:offset
											   attachedToAnchor:anchorPoint];
		attachment.length = 0.0f;
		
		// create elasticity
//		UIDynamicItemBehavior *itemBehaviour = [[UIDynamicItemBehavior alloc] initWithItems:@[gesture.view]];
//		itemBehaviour.elasticity = 1.0f;
//		itemBehaviour.density = 100.0f;
//		itemBehaviour.angularResistance = 20.0f;
//		[self.animator addBehavior:itemBehaviour];
		
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
		attachment.anchorPoint = anchorPoint;
	}
	else if (gesture.state == UIGestureRecognizerStateEnded)
	{
		[self.animator removeAllBehaviors];
		
		CGPoint velocity = [gesture velocityInView:gesture.view.superview];
		CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
		// if magnitude is low, snap back to original position and return
		if (magnitude < 2000)
		{
			UISnapBehavior *snap = [[UISnapBehavior alloc] initWithItem:gesture.view snapToPoint:self.view.center];
			snap.damping = 0.8f;
			[self.animator addBehavior:snap];
			return;
		}
		// otherwise, create UIDynamicItemBehavior that carries on animation from where the gesture left off (notably linear and angular velocity)
		UIDynamicItemBehavior *itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[gesture.view]];
		[itemBehavior addLinearVelocity:velocity forItem:gesture.view];
		[itemBehavior addAngularVelocity:angularVelocity forItem:gesture.view];
		
		itemBehavior.angularResistance = 1.25f;
		itemBehavior.density = 2.0f;
		itemBehavior.resistance = -1.0f;
		
		// when the view no longer intersects with its superview, go ahead and remove it
		typeof(self) __weak weakSelf = self;
		itemBehavior.action = ^{
			// TODO fade dimmingView alpha based on progress from centrepoint to exitpoint
			if (!CGRectIntersectsRect(gesture.view.superview.bounds, gesture.view.frame))
			{
				[weakSelf.animator removeAllBehaviors];
				[gesture.view removeFromSuperview];
				
				[self dismissViewControllerAnimated:YES completion:nil];
			}
		};
		
		[self.animator addBehavior:itemBehavior];
		
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

- (IBAction) handleTap:(UITapGestureRecognizer *)tapRecognizer
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
