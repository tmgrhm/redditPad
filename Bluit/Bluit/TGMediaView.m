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

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *captionLabel;

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
	self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
	self.scrollView.clipsToBounds = NO;
	self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.scrollView.delegate = self;
	self.scrollView.minimumZoomScale = 0.5;
	self.scrollView.maximumZoomScale = 3.0;
	//	self.scrollView.scrollEnabled = NO;
	self.scrollView.canCancelContentTouches = NO;
	[self addSubview:self.scrollView];
	
	self.containerView.clipsToBounds = NO;
	self.containerView = [[UIView alloc] initWithFrame:self.scrollView.bounds];
	self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.scrollView addSubview:self.containerView];
	
	self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.containerView.frame.size.width/2, self.containerView.frame.size.height/2, 0, 0)];
	self.imageView.contentMode = UIViewContentModeScaleAspectFit;
	self.imageView.userInteractionEnabled = YES;
	self.imageView.layer.allowsEdgeAntialiasing = YES;
	[self setContentView:self.imageView];
	
	[self configureTitleLabel];
	[self configureCaptionLabel];
	
	self.hasLaidOut = YES;
	
	if (self.mediaURL) [self loadMediaFromURL:self.mediaURL];
	
	[self themeAppearance];
}

#pragma mark - Appearance

- (void) themeAppearance
{
	// TODO?
	
//	self.scrollView.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.2f];
//	self.containerView.backgroundColor = [[UIColor yellowColor] colorWithAlphaComponent:0.2f];
//	self.imageView.alpha = 0.0f;
}

- (void) configureTitleLabel
{
	UILabel *titleLabel = [UILabel new]; // TODO
	
	titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:titleLabel];
	NSDictionary *metrics = @{@"topMargin":@(60)};
	NSDictionary *views = NSDictionaryOfVariableBindings(titleLabel);
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[titleLabel]|" options:0 metrics:nil views:views]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(topMargin)-[titleLabel]" options:0 metrics:metrics views:views]];
	
	titleLabel.textAlignment = NSTextAlignmentCenter;
	titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:17.0f];
	titleLabel.textColor = [UIColor whiteColor];
	titleLabel.numberOfLines = 0;
	
	self.titleLabel = titleLabel;
}

- (void) configureCaptionLabel
{
	UILabel *captionLabel = [UILabel new]; // TODO
	
	captionLabel.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:captionLabel];
	NSDictionary *metrics = @{@"btmMargin":@(60)};
	NSDictionary *views = NSDictionaryOfVariableBindings(captionLabel);
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[captionLabel]|" options:0 metrics:nil views:views]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[captionLabel]-(btmMargin)-|" options:0 metrics:metrics views:views]];
	
	captionLabel.textAlignment = NSTextAlignmentCenter;
	captionLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:15.0f];
	captionLabel.textColor = [UIColor whiteColor];
	captionLabel.numberOfLines = 0;
	
	self.captionLabel = captionLabel;
}

#pragma mark - Getters & Setters

- (void) setTitle:(NSString *)title
{
	_title = title;
	self.titleLabel.text = title;
}

- (void) setCaption:(NSString *)caption
{
	_caption = caption;
	self.captionLabel.text = caption;
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

#pragma Loading Content

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
	if ([contentView class] == [UIImageView class])	[self layoutWithContentSize:self.imageView.image.size];
	else if (contentView == self.moviePlayer.view)	[self layoutWithContentSize:self.moviePlayer.naturalSize];
}

- (void) layoutWithContentSize:(CGSize)contentSize
{
	if (contentSize.height == 0 && contentSize.width == 0) return;
	
	// calculate scale required to fit inside scrollView
	CGFloat scaleWidth = CGRectGetWidth(self.scrollView.frame) / contentSize.width;
	CGFloat scaleHeight = CGRectGetHeight(self.scrollView.frame) / contentSize.height;
	CGFloat scale = MIN(scaleWidth, scaleHeight);
	
	// calculate scaled size
	CGPoint midpoint = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)); // TODO sometimes self.bounds is 0,0,0,0 (generally when media is direct image link, b/c that's quicker)
	CGSize scaledContentSize = CGSizeMake(contentSize.width * scale, contentSize.height * scale);
	CGRect targetRect = CGRectMake(midpoint.x - scaledContentSize.width / 2.0, midpoint.y - scaledContentSize.height / 2.0, scaledContentSize.width, scaledContentSize.height);
	// … and use it for size of contentView + scrollView.contentSize
	UIView *contentView = self.containerView.subviews[0];
	contentView.frame = targetRect;
	self.scrollView.contentSize = targetRect.size;
	
	if (scale < 1.0f) // TODO improve whatever exactly this does
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

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
	[self centerScrollViewContents];
	
	// zoomScale of 1.0 is always our starting point, so anything other than that we disable the pan gesture recognizer
//	if (scrollView.zoomScale <= 1.0f && !scrollView.zooming)
//	{
		// TODO
//		[self enablePanGesture:YES];
//		scrollView.scrollEnabled = NO;
//	}
//	else
//	{
		// TODO
//		[self enablePanGesture:NO];
//		scrollView.scrollEnabled = YES;
//	}
	
//
//	if (scrollView.zoomScale > 1.0 && !scrollView.zooming)
//	{
//		self.containerView.frame = CGRectMake(0, 0, scrollView.contentSize.width, scrollView.contentSize.height);
//	}
//	else
//	{
//		self.containerView.frame = self.scrollView.bounds;
//	}
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
