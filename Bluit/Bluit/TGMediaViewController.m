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
@import MediaPlayer;

@interface TGMediaViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate, UIDynamicAnimatorDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *fadeView;
@property (strong, nonatomic) UIView *containerView;

@property (strong, nonatomic) MPMoviePlayerController *moviePlayer;
@property (strong, nonatomic) UIImageView *imageView;

@property (strong, nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (strong, nonatomic) UIDynamicAnimator *animator;

@property (nonatomic) CGPoint originalCenter;
@property (nonatomic) CGFloat minScale;

@property (nonatomic) BOOL hasLaidOut;

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
	
	self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.containerView.frame.size.width/2, self.containerView.frame.size.height/2, 0, 0)];
	self.imageView.contentMode = UIViewContentModeScaleAspectFit;
	self.imageView.userInteractionEnabled = YES;
	self.imageView.layer.allowsEdgeAntialiasing = YES;
	[self setContentView:self.imageView];
	
	self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
	self.panRecognizer.delegate = self;
	[self.containerView addGestureRecognizer:self.panRecognizer];
	
	self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
//	self.animator.delegate = self;
	
	self.hasLaidOut = YES;
	
	if (self.mediaURL) [self loadMediaFromURL:self.mediaURL];
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

- (void) setContentView:(UIView *)contentView
{
	for (UIView *view in self.containerView.subviews) [view removeFromSuperview]; // remove any existing views
//	contentView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.containerView addSubview:contentView];
//	NSDictionary *views = NSDictionaryOfVariableBindings(contentView);
//	[self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|" options:0 metrics:nil views:views]];
//	[self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contentView]|" options:0 metrics:nil views:views]];
}

- (void)loadMediaFromURL:(NSURL *)url
{
	self.mediaURL = url;
	
	if (!self.hasLaidOut) return;
	
	NSString *fileExtension = [[[url absoluteString] lastPathComponent] pathExtension];
	
	if ([fileExtension hasPrefix:@"mp4"])
		[self setVideoWithURL:url];
	else // image
		[self setImageWithURL:url];
}

- (void) setImageWithURL:(NSURL *)imageURL
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:imageURL];
 	[request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
	
 	UIImageView *imageView = self.containerView.subviews[0];
	if (!imageView) return;
 
//	UIImageView *imageView = self.imageView;
	__block UIImageView *blockImageView = imageView;
	__weak __typeof(self)weakSelf = self;
	
	[imageView setImageWithURLRequest:request placeholderImage:imageView.image success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
		{
			[UIView transitionWithView:blockImageView
							  duration:0.3f
							   options:UIViewAnimationOptionTransitionCrossDissolve
							animations:^{
								weakSelf.imageView.image = image;
								[weakSelf layoutWithContentSize:image.size];
							} // TODO make consistently smooth + performant
							completion:NULL];
		} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
			// TODO
		}];
}

- (void) setVideoWithURL:(NSURL *)videoURL
{
	MPMoviePlayerController *player = [MPMoviePlayerController new];
	self.moviePlayer = player;
	player.contentURL = videoURL;
	[player prepareToPlay];
	player.scalingMode = MPMovieScalingModeAspectFit;
	player.repeatMode = MPMovieRepeatModeOne;
	player.controlStyle = MPMovieControlStyleNone;
	// centred, zero-size frame until we get the video size in videoDidLoad, after which we layoutWithContentSize
	player.view.frame = CGRectMake(self.containerView.frame.size.width/2, self.containerView.frame.size.height/2, 0, 0);
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoDidLoad) name:@"MPMoviePlayerContentPreloadDidFinishNotification" object:self.moviePlayer];
}

- (void) videoDidLoad
{
	if (self.moviePlayer.loadState == MPMovieLoadStatePlayable || self.moviePlayer.loadState == MPMovieLoadStatePlaythroughOK)
	{
		__weak __typeof(self)weakSelf = self;
		[UIView transitionWithView:self.containerView
						  duration:0.3f
						   options:UIViewAnimationOptionTransitionCrossDissolve
						animations:^{
							[weakSelf setContentView:weakSelf.moviePlayer.view];
							[weakSelf layoutWithContentSize:weakSelf.moviePlayer.naturalSize];
						}
						completion:NULL];
		
		[self.moviePlayer play];
	}
}

- (void) layoutWithContentSize:(CGSize)contentSize
{
	// update scrollView.contentSize to the size of the content
	self.scrollView.contentSize = contentSize;
	CGFloat scaleWidth = CGRectGetWidth(self.scrollView.frame) / self.scrollView.contentSize.width;
	CGFloat scaleHeight = CGRectGetHeight(self.scrollView.frame) / self.scrollView.contentSize.height;
	CGFloat scale = MIN(scaleWidth, scaleHeight);
	
	// content view's destination frame is the size of the content capped to the width/height of the target view
	CGPoint midpoint = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
	CGSize scaledContentSize = CGSizeMake(contentSize.width * scale, contentSize.height * scale);
	CGRect targetRect = CGRectMake(midpoint.x - scaledContentSize.width / 2.0, midpoint.y - scaledContentSize.height / 2.0, scaledContentSize.width, scaledContentSize.height);
	
	UIView *contentView = self.containerView.subviews[0];
	contentView.frame = targetRect;
	
	if (scale < 1.0f)
	{
		self.scrollView.minimumZoomScale = 1.0f;
		self.scrollView.maximumZoomScale = 1.0f / scale;
	}
	else
	{
		self.scrollView.minimumZoomScale = 1.0f / scale;
		self.scrollView.maximumZoomScale = 1.0f;
	}
	
	self.minScale = self.scrollView.minimumZoomScale;
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
