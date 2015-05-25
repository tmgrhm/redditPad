//
//  TGMediaViewController.m
//  redditPad
//
//  Created by Tom Graham on 27/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGMediaViewController.h"
#import "ThemeManager.h"

#import <AFNetworking/UIImageView+AFNetworking.h>

@interface TGMediaViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate, UIDynamicAnimatorDelegate>

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIView *containerView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *fadeView;

@property (strong, nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (strong, nonatomic) UIDynamicAnimator *animator;

@property (nonatomic) CGPoint originalCenter;

@property (nonatomic) CGFloat minScale;
@property (nonatomic) CGFloat maxScale;
@property (nonatomic) CGFloat lastPinchScale;

@end

@implementation TGMediaViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self themeAppearance];
	
	self.scrollView.delegate = self;
	self.scrollView.minimumZoomScale = 0.5;
	self.scrollView.maximumZoomScale = 3.0;
//	self.scrollView.scrollEnabled = NO;
	self.scrollView.canCancelContentTouches = NO;
	
	self.containerView = [[UIView alloc] initWithFrame:self.view.bounds];
	self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.scrollView addSubview:self.containerView];
	
	self.imageView.contentMode = UIViewContentModeScaleAspectFit;
	self.imageView.userInteractionEnabled = YES;
	self.imageView.layer.allowsEdgeAntialiasing = YES;
	[self.containerView addSubview:self.imageView];
	
	self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
	self.panRecognizer.delegate = self;
	[self.containerView addGestureRecognizer:self.panRecognizer];
	
	self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
//	self.animator.delegate = self;
}

- (void)didReceiveMemoryWarning {
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

-(UIImageView *)imageView
{
	if (!_imageView) _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
	return _imageView;
}

- (void)setImage:(UIImage *)image
{
	self.imageView.image = image;
	
	// update scrollView.contentSize to the size of the image
	self.scrollView.contentSize = image.size;
	CGFloat scaleWidth = CGRectGetWidth(self.scrollView.frame) / self.scrollView.contentSize.width;
	CGFloat scaleHeight = CGRectGetHeight(self.scrollView.frame) / self.scrollView.contentSize.height;
	CGFloat scale = MIN(scaleWidth, scaleHeight);
	
	// image view's destination frame is the size of the image capped to the width/height of the target view
	CGPoint midpoint = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
	CGSize scaledImageSize = CGSizeMake(image.size.width * scale, image.size.height * scale);
	CGRect targetRect = CGRectMake(midpoint.x - scaledImageSize.width / 2.0, midpoint.y - scaledImageSize.height / 2.0, scaledImageSize.width, scaledImageSize.height);
	
	self.imageView.frame = targetRect;
	
	if (scale < 1.0f) {
		self.scrollView.minimumZoomScale = 1.0f;
		self.scrollView.maximumZoomScale = 1.0f / scale;
	}
	else {
		self.scrollView.minimumZoomScale = 1.0f / scale;
		self.scrollView.maximumZoomScale = 1.0f;
	}
	
	self.minScale = self.scrollView.minimumZoomScale;
	self.maxScale = self.scrollView.maximumZoomScale;
	self.lastPinchScale = 1.0f;
}

- (void)loadMediaFromURL:(NSURL *)url
{
	self.mediaURL = url;
	
	NSString *fileExtension = [[[url absoluteString] lastPathComponent] pathExtension];
	
	if ([fileExtension hasPrefix:@"mp4"])
		[self loadVideoFromURL:url];
	else // image
		[self loadImageFromURL:url];
}

- (void) loadVideoFromURL:(NSURL *)url
{
	// TODO
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loadImageFromURL:(NSURL *)url
{
	__weak __typeof(self)weakSelf = self;
	[self.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:url]
						  placeholderImage:[UIImage imageNamed:@"Icon-Navbar-Refresh"] // TODO loader
								   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
	{
		[weakSelf setImage: image];
	}
								   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)
	{
		NSLog(@"Failure loading image :(");
	}];
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

- (IBAction)handleDismissTap:(UITapGestureRecognizer *)tapRecognizer
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	CGFloat transformScale = self.imageView.transform.a;
	BOOL shouldRecognize = transformScale > _minScale;
	
	return shouldRecognize;
}

#pragma mark - UIScrollView

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
	// zoomScale of 1.0 is always our starting point, so anything other than that we disable the pan gesture recognizer
	if (scrollView.zoomScale <= 1.0f && !scrollView.zooming)
	{
		[self enablePanGesture:YES];
//		scrollView.scrollEnabled = NO;
	}
	else
	{
		[self enablePanGesture:NO];
//		scrollView.scrollEnabled = YES;
	}
	[self centerScrollViewContents];
	
	if (scrollView.zoomScale > 1.0)
	{
		self.containerView.frame = CGRectMake(0, 0, scrollView.contentSize.width, scrollView.contentSize.height);
	}
	else
	{
		self.containerView.frame = self.scrollView.bounds;
	}
}

#pragma mark - Convenience

- (void)centerScrollViewContents
{
	CGSize contentSize = self.scrollView.contentSize;
	CGFloat offsetX = (CGRectGetWidth(self.scrollView.frame) > contentSize.width) ? (CGRectGetWidth(self.scrollView.frame) - contentSize.width) / 2.0f : 0.0f;
	CGFloat offsetY = (CGRectGetHeight(self.scrollView.frame) > contentSize.height) ? (CGRectGetHeight(self.scrollView.frame) - contentSize.height) / 2.0f : 0.0f;
	self.imageView.center = CGPointMake(self.scrollView.contentSize.width / 2.0f + offsetX, self.scrollView.contentSize.height / 2.0f + offsetY);
}

- (CGFloat)angleOfView:(UIView *)view
{
	// http://stackoverflow.com/a/2051861/1271826
	
	return atan2(view.transform.b, view.transform.a);
}

@end
