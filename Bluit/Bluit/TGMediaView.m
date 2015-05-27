//
//  TGMediaView.m
//  redditPad
//
//  Created by Tom Graham on 27/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGMediaView.h"

#import "ThemeManager.h"

#import <AFNetworking/UIImageView+AFNetworking.h>
@import MediaPlayer;

@interface TGMediaView () <UIScrollViewDelegate>

@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) UIScrollView *scrollView;

@property (strong, nonatomic) MPMoviePlayerController *moviePlayer;
@property (strong, nonatomic) UIImageView *imageView;

@property (nonatomic) CGFloat minScale;

@property (nonatomic) BOOL hasLaidOut;

@end

@implementation TGMediaView

- (instancetype) init
{
	if (self = [super init])
	{
		[self commonInit];
	}
	return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		[self commonInit];
	}
	return self;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super initWithCoder:aDecoder])
	{
		[self commonInit];
	}
	return self;
}

- (void) commonInit
{
	[self themeAppearance];
	
	self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
	self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.scrollView.delegate = self;
	self.scrollView.minimumZoomScale = 0.5;
	self.scrollView.maximumZoomScale = 3.0;
	//	self.scrollView.scrollEnabled = NO;
	self.scrollView.canCancelContentTouches = NO;
	[self addSubview:self.scrollView];
	
	self.containerView = [[UIView alloc] initWithFrame:self.bounds];
	self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.scrollView addSubview:self.containerView];
	
	self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.containerView.frame.size.width/2, self.containerView.frame.size.height/2, 0, 0)];
	self.imageView.contentMode = UIViewContentModeScaleAspectFit;
	self.imageView.userInteractionEnabled = YES;
	self.imageView.layer.allowsEdgeAntialiasing = YES;
	[self setContentView:self.imageView];
	
	self.hasLaidOut = YES;
	
	if (self.mediaURL) [self loadMediaFromURL:self.mediaURL];
}

- (void) themeAppearance
{
	// empty
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

- (void) loadMediaFromURL:(NSURL *)url
{
	NSLog(@"loading %@", url);
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

#pragma mark - Layout

- (void) layoutSubviews
{
	[super layoutSubviews];
	
	UIView *contentView = self.containerView.subviews[0];
	if (contentView == self.imageView)				[self layoutWithContentSize:self.imageView.image.size];
	else if (contentView == self.moviePlayer.view)	[self layoutWithContentSize:self.moviePlayer.naturalSize];
}

- (void) layoutWithContentSize:(CGSize)contentSize
{
	NSLog(@"laying out with %f %f", contentSize.width, contentSize.height);
	if (contentSize.height == 0 && contentSize.width == 0) return;
	
	// update scrollView.contentSize to the size of the content
	self.scrollView.contentSize = contentSize;
	CGFloat scaleWidth = CGRectGetWidth(self.scrollView.frame) / self.scrollView.contentSize.width;
	CGFloat scaleHeight = CGRectGetHeight(self.scrollView.frame) / self.scrollView.contentSize.height;
	CGFloat scale = MIN(scaleWidth, scaleHeight);
	
	// content view's destination frame is the size of the content capped to the width/height of the target view
	CGPoint midpoint = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
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

#pragma mark - UIScrollView

- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return self.containerView.subviews[0];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
	// zoomScale of 1.0 is always our starting point, so anything other than that we disable the pan gesture recognizer
	if (scrollView.zoomScale <= 1.0f && !scrollView.zooming)
	{
		// TODO
//		[self enablePanGesture:YES];
//		scrollView.scrollEnabled = NO;
	}
	else
	{
		// TODO
//		[self enablePanGesture:NO];
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

@end
