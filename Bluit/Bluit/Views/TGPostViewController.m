//
//  TGPostViewController.m
//  redditPad
//
//  Created by Tom Graham on 23/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGPostViewController.h"

#import "TGComment.h"
#import "TGMoreComments.h"

#import "TGCommentTableViewCell.h"
#import "TGWebViewController.h"
#import "TGLinkPostCell.h"
#import "TGTweetView.h"

#import "ThemeManager.h"
#import "TGRedditClient.h"
#import "TGImgurClient.h"
#import "TGTwitterClient.h"

#import "TGRedditMarkdownParser.h"
#import "NSDate+RelativeDateString.h"

#import "TGFormPresentationController.h"
#import "TGFormAnimationController.h"

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <TUSafariActivity/TUSafariActivity.h>
#import <MWFeedParser/NSString+HTML.h>
#import "UIImageEffects.h"

static CGFloat const PreviewImageMaxHeight = 300.0f;

typedef NS_ENUM(NSUInteger, PostViewEmbeddedMediaType)
{
	EmbeddedMediaNone = 0,
	EmbeddedMediaDirectImage,
	EmbeddedMediaImgur,
	EmbeddedMediaInstagram,
	EmbeddedMediaTweet
};

@interface TGPostViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UIBarPositioningDelegate>

@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (weak, nonatomic) IBOutlet UITableView *commentTableView;
@property (weak, nonatomic) IBOutlet UIToolbar *topToolbar;
@property (weak, nonatomic) CAShapeLayer *topToolbarShadow;
@property (weak, nonatomic) IBOutlet UIImageView *previewImage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewImageHeight;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *savePostButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *hidePostButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sharePostButton;

@property (nonatomic) PostViewEmbeddedMediaType embeddedMediaType;
@property (strong, nonatomic) NSDictionary *embeddedMediaData;
@property (nonatomic) BOOL isImagePost;
@property (nonatomic) CGFloat postHeaderHeight;
@property (strong, nonatomic) TGLinkPostCell *postHeader;

@property (strong, nonatomic) NSArray *originalComments; // original comments as returned from API
@property (strong, nonatomic) NSMutableArray *comments; // comments to display (excluding collapsed children)
@property (strong, nonatomic) NSMutableSet *collapsedComments; // comments at the root of a collapse
@property (strong, nonatomic) NSMutableDictionary *commentHeights;
@property (strong, nonatomic) NSMutableDictionary *cachedAttributedStrings;
@property (strong, nonatomic) TGCommentTableViewCell *sizingCell;

@property (strong, nonatomic) NSURL *interactedURL;

- (void) reloadCommentTableViewData;

@end

@implementation TGPostViewController

#pragma mark - Getters & Setters

- (void) setOriginalComments:(NSArray *)comments
{
	_originalComments = comments;
	self.comments = [comments mutableCopy];
}

- (BOOL) isRichPost
{
	if (self.embeddedMediaType != EmbeddedMediaNone) return YES; // cheap check after first use
	
	if ([[TGTwitterClient sharedClient] URLisTwitterLink:self.link.url])
	{
		self.embeddedMediaType = EmbeddedMediaTweet;
		return YES;
	}
	else if (self.link.isImageLink)
	{
		self.embeddedMediaType = EmbeddedMediaDirectImage;
		return YES;
	}
	else if ([[TGImgurClient sharedClient] URLisImgurLink:self.link.url])
	{
		self.embeddedMediaType = EmbeddedMediaImgur;
		return YES;
	}
	
	return NO;
}

- (BOOL) isImagePost
{
	switch (self.embeddedMediaType) {
		case EmbeddedMediaDirectImage:
		case EmbeddedMediaImgur:
		case EmbeddedMediaInstagram:
			return YES;
			break;
		default:
			return NO;
			break;
	}
}

#pragma mark - Init

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	[self commonInit];
	return self;
}

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	[self commonInit];
	return self;
}

- (void) commonInit
{
	self.transitioningDelegate = self;
	self.modalTransitionStyle = UIModalPresentationCustom;
	self.preferredContentSize = CGSizeMake(668, 876);
	
	self.comments = [NSMutableArray new];
	self.collapsedComments = [NSMutableSet new];
	self.commentHeights = [NSMutableDictionary new];
	self.cachedAttributedStrings = [NSMutableDictionary new];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	
	[self createShadow];
	[self themeAppearance];
	[self configureContentInsets];
	[self configureGestureRecognizer];
	
	__weak __typeof(self)weakSelf = self;
	[[TGRedditClient sharedClient] requestCommentsForLink:self.link withCompletion:^(NSArray *comments)
	 {
		 [weakSelf commentsFromResponse:comments];
	 }];
	
	if ([self isRichPost])		[self configureEmbeddedMedia];
	if (![self isImagePost])	[self setToolbarAlpha:1];
}

- (void) viewDidAppear:(BOOL)animated
{
	// TODO only insert comments + tweetView after this?
	// use NSNotification to trigger a method to display the comments + tweet content to prevent lagging while presenting the view
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - Setup & Customisation

- (void)createShadow
{
//	CALayer *containerCALayer = self.shadowView.layer;
//	containerCALayer.borderColor = [[ThemeManager shadowBorderColor] CGColor];
//	containerCALayer.borderWidth = 0.6f;
}

- (void) themeAppearance
{
	self.commentTableView.backgroundColor = [UIColor clearColor];
	self.containerView.backgroundColor = [ThemeManager colorForKey:kTGThemeBackgroundColor];
	
	[self configureToolbarShadow];
}

- (void) configureContentInsets
{
	[self.commentTableView setContentInset:UIEdgeInsetsMake(self.topToolbar.frame.size.height, 0, 0, 0)];
	[self.commentTableView setScrollIndicatorInsets:self.commentTableView.contentInset];
}

- (void) configureGestureRecognizer
{
	UISwipeGestureRecognizer *singleSwipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self  action:@selector(singleSwipeLeft:)];
	singleSwipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
	singleSwipeLeft.numberOfTouchesRequired = 1;
	singleSwipeLeft.delegate = self;
	[self.commentTableView addGestureRecognizer:singleSwipeLeft];
	
	UISwipeGestureRecognizer *doubleSwipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self  action:@selector(doubleSwipeLeft:)];
	doubleSwipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
	doubleSwipeLeft.numberOfTouchesRequired = 2;
	doubleSwipeLeft.delegate = self;
	[self.commentTableView addGestureRecognizer:doubleSwipeLeft];
}

- (void) configureEmbeddedMedia
{
	switch (self.embeddedMediaType)
	{
		case EmbeddedMediaDirectImage:
		{
			// set placeholder from blurredthumbnail
			// should be cached due to showing on listingVC — won't if this view came from a direct link so TODO consider that
			[self.previewImage setImageWithURL:self.link.thumbnailURL];
			UIImage *placeholder = [UIImageEffects imageByApplyingBlurToImage:self.previewImage.image withRadius:0.9 tintColor:nil saturationDeltaFactor:1.4 maskImage:nil];
			
			[self preparePreviewImage]; // set up to display previewImage
			
			[self setPreviewImageWithURL:self.link.url andPlaceholder:placeholder];
			break;
		}
		case EmbeddedMediaImgur:
		{
			// set placeholder from blurredthumbnail
			// should be cached due to showing on listingVC — won't if this view came from a direct link so TODO consider that
			[self.previewImage setImageWithURL:self.link.thumbnailURL];
			UIImage *placeholder = [UIImageEffects imageByApplyingBlurToImage:self.previewImage.image withRadius:0.9 tintColor:nil saturationDeltaFactor:1.4 maskImage:nil];
			self.previewImage.image = placeholder;
			
			[self preparePreviewImage]; // set up to display previewImage
			
			[[TGImgurClient sharedClient] directImageURLfromImgurURL:self.link.url success:^(NSURL *imageURL) {
				[self setPreviewImageWithURL:imageURL andPlaceholder:placeholder];
			}];
			break;
		}
		case EmbeddedMediaTweet:
		{
			[[TGTwitterClient sharedClient] tweetWithID:[[TGTwitterClient sharedClient] tweetIDfromLink:self.link.url] success:^(id responseObject) {
				self.embeddedMediaData = (NSDictionary *) responseObject;
				
				// check view in contentContainerView is a TweetView
				UIView *contentContainerSubview = [self.postHeader.contentContainerView subviews][0];
				TGTweetView *tweetView;
				if ([contentContainerSubview class] == [TGTweetView class]) tweetView = (TGTweetView *) contentContainerSubview;
				else
				{
					NSLog(@"error, abort abort, contentContainerSubview not a TweetView");
					return;
				}
				
				// configure tweet view data and colours
				[self configureTweetView:tweetView];

				// recalculate headerHeight
				self.postHeaderHeight = 0;
				[self.commentTableView beginUpdates];
				// this causes a reload heights of cells; doesn't seem there's another easy way to do this
				[self.commentTableView endUpdates];
			}];
			
			break;
		}
		default:
		{
			NSLog(@"I shouldn't be here…"); // TODO doublecheck
			return;
		}
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// TODO
	// pull images for use as previewImage from APIs, e.g. imgur
	// tap previewImage to view in fullscreen picture viewer
	// swiping between images in previewImage if gallery?
}

- (void) preparePreviewImage
{
	[self setToolbarAlpha:0];
	
	// calculate height to be added to top of tableView
	UIImage *image = self.previewImage.image; // thumbnail, generally has same aspect ratio
	if (image != nil)
	{
		CGFloat newWidth = self.previewImage.frame.size.width;
		CGFloat aspectFilledImageHeight = (image.size.height / image.size.width) * newWidth;
		self.previewImageHeight.constant = MIN(PreviewImageMaxHeight, aspectFilledImageHeight); // restrict to max height
	}
	else self.previewImageHeight.constant = PreviewImageMaxHeight; // TODO handle empty thumbnails on image posts
	
	// add empty space to top of tableView
	UIEdgeInsets insets = self.commentTableView.contentInset;
	insets.top = self.previewImageHeight.constant;
	self.commentTableView.contentInset = insets;
}

- (void) setPreviewImageWithURL:(NSURL *)imageURL andPlaceholder:(UIImage *)placeholder
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:imageURL];
	[request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
	[self.previewImage setImageWithURLRequest:request placeholderImage:placeholder success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
		{
			[UIView transitionWithView:self.previewImage
							  duration:0.3f
							   options:UIViewAnimationOptionTransitionCrossDissolve
							animations:^{[self.previewImage setImage:image];} // TODO make consistently smooth + performant
							completion:NULL];
		} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
			// TODO
		}];
}

- (void) configureTweetView:(TGTweetView *)tweetView
{
	NSDictionary *data = self.embeddedMediaData;
	if (data)
	{
		[UIView transitionWithView:tweetView
						  duration:0.3f
						   options:UIViewAnimationOptionTransitionCrossDissolve
						animations:^{
							[tweetView setSkeleton:NO]; // configure colours, undo skeleton structure appearance
							
							// get larger profile img size https://dev.twitter.com/overview/general/user-profile-images-and-banners
							NSString *userProfileImageURL = [data[@"user"][@"profile_image_url_https"] stringByReplacingOccurrencesOfString:@"_normal" withString:@"_bigger"];
							[tweetView.userProfileImage setImageWithURL:[NSURL URLWithString:userProfileImageURL]];
							tweetView.userName.text = data[@"user"][@"name"];
							tweetView.userScreenname.text = [@"@" stringByAppendingString:data[@"user"][@"screen_name"]];
							tweetView.timestamp.text = data[@"created_at"];
							
							NSString *tweetText = [data[@"text"] stringByDecodingHTMLEntities];
							tweetView.tweetText.text = tweetText;
						}
						completion:NULL];
	}
}

- (void) updateSaveButton
{
	UIColor *tintColor;
	
	if (self.link.isSaved)	tintColor = [ThemeManager colorForKey:kTGThemeSaveColor];
	else						tintColor = [self toolbarIsTransparent] ? [UIColor whiteColor] : [ThemeManager colorForKey:kTGThemeInactiveColor];
	
	self.savePostButton.tintColor = tintColor;
}

- (void) updateHideButton
{
	UIImage *image;
	UIColor *tintColor;
	
	if (self.link.isHidden)
	{
		image = [UIImage imageNamed:@"Icon-Post-Hide-Active"];
		tintColor = [ThemeManager colorForKey:kTGThemeTintColor];
	}
	else
	{
		image = [UIImage imageNamed:@"Icon-Post-Hide-Inactive"];
		tintColor = [ThemeManager colorForKey:kTGThemeInactiveColor];
	}
	if ([self toolbarIsTransparent]) tintColor = [UIColor whiteColor];
	
	self.hidePostButton.image = image;
	self.hidePostButton.tintColor = tintColor;
}

- (void) updateVoteButtons
{
	switch (self.link.voteStatus)	// TODO why isn't this reflecting properly in UI on viewDidAppear of postVC
	{
		case TGVoteStatusNone:
			self.postHeader.upvoteButton.selected = NO;
			self.postHeader.downvoteButton.selected = NO;
			break;
		case TGVoteStatusDownvoted:
			self.postHeader.upvoteButton.selected = NO;
			self.postHeader.downvoteButton.selected = YES;
			break;
		case TGVoteStatusUpvoted:
			self.postHeader.upvoteButton.selected = YES;
			self.postHeader.downvoteButton.selected = NO;
			break;
	}
}

- (void) setToolbarAlpha:(CGFloat)alpha
{
	UIColor *barBackgroundColor;
	UIImage *barBackgroundImage;
	UIImage *barShadowImage;
	UIColor *barShadowColor;
	CGFloat barShadowWidth;
	UIColor *buttonTintColor;
	
	CGFloat currentAlpha;
	[self.topToolbar.backgroundColor getWhite:nil alpha:&currentAlpha];
	
	// if alpha == 0, should be clear BG + white tint
	// if 0 < alpha < 1, should be calculated
	// if alpha > 1, should be white BG + blue tint
	
	if (alpha <= 0.0f) // definitely transparent
	{
		if (currentAlpha == 0.0f) return;
		
		barBackgroundColor = [UIColor clearColor];
		barBackgroundImage = [UIImage imageNamed:@"BG-Navbar-OverImage"];
		barShadowImage = [UIImage imageNamed:@"BG-Navbar-OverImage-Shadow"];
		barShadowColor = [UIColor clearColor];
		barShadowWidth = 0.0f;
		buttonTintColor = [UIColor whiteColor];
	}
	else if (alpha >= 1.0f) // definitely opaque
	{
		if (currentAlpha == 1.0f) return;
		
		barBackgroundColor = [ThemeManager colorForKey:kTGThemeContentBackgroundColor];
		barBackgroundImage = [UIImage new];
		barShadowImage = [UIImage new];
		barShadowColor = [ThemeManager colorForKey:kTGThemeSeparatorColor];
		barShadowWidth = 1.0f / [[UIScreen mainScreen] scale];
		buttonTintColor = [ThemeManager colorForKey:kTGThemeTintColor];
	}
	else // in between transparent and opaque
	{
		// get start color's saturation and brightness
		CGFloat startSaturation, startBrightness;
		[[UIColor whiteColor] getHue:nil saturation:&startSaturation brightness:&startBrightness alpha:nil];
		// get end color's saturation and brightness
		CGFloat endHue, endSaturation, endBrightness;
		[[ThemeManager colorForKey:kTGThemeTintColor] getHue:&endHue saturation:&endSaturation brightness:&endBrightness alpha:nil];
		// calculate difference from start to end, multiply by progress factor
		CGFloat progress = alpha;
		UIColor *tintColor = [UIColor colorWithHue:endHue
										saturation:startSaturation - ((startSaturation - endSaturation) * progress)
										brightness:startBrightness - ((startBrightness - endBrightness) * progress)
											 alpha:1.0];
		
		barBackgroundColor = [[ThemeManager colorForKey:kTGThemeContentBackgroundColor] colorWithAlphaComponent:alpha];
		barShadowColor = [[ThemeManager colorForKey:kTGThemeSeparatorColor] colorWithAlphaComponent:alpha];
		barShadowWidth = 1.0f / [[UIScreen mainScreen] scale];
		buttonTintColor = tintColor;
	}
	
	// toolbar background
	self.topToolbar.backgroundColor = barBackgroundColor;
	[self.topToolbar setBackgroundImage:barBackgroundImage forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
	[self.topToolbar setShadowImage:barShadowImage forToolbarPosition:UIBarPositionTop];
	
	// set barButtonItem color
	self.topToolbar.tintColor = buttonTintColor;
	[self updateSaveButton]; // must be after setting toolbarBG color (uses it to decide what color)
	[self updateHideButton]; // ^ same
	
	// toolbar border/shadow // TODO test performance between two
//	self.topToolbar.layer.borderColor = [barShadowColor CGColor];
//	self.topToolbar.layer.borderWidth = barShadowWidth;
	
	self.topToolbarShadow.fillColor = [barShadowColor CGColor];
}

- (void) configureToolbarShadow
{
	CGRect shadowRect = CGRectMake(0, 0, self.topToolbar.frame.size.width, 0.5f);
	CAShapeLayer *shapeLayer = [CAShapeLayer layer];
	shapeLayer.path = CGPathCreateWithRect(shadowRect, NULL);
	shapeLayer.fillColor = [[ThemeManager colorForKey:kTGThemeSeparatorColor] CGColor];
	shapeLayer.position = CGPointMake(0.0, self.topToolbar.frame.size.height);
	
	[self.topToolbar.layer addSublayer:shapeLayer];
	self.topToolbarShadow = shapeLayer;
}

#pragma mark - IBActions

- (IBAction)closePressed:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)savePostPressed:(id)sender
{
	if ([self.link isSaved])
	{
		[[TGRedditClient sharedClient] unsave:self.link];
		self.link.saved = NO;
	}
	else
	{
		[[TGRedditClient sharedClient] save:self.link];
		self.link.saved = YES;
	}
	[self updateSaveButton];
}

- (IBAction)hidePostPressed:(id)sender
{
	if ([self.link isHidden])
	{
		[[TGRedditClient sharedClient] unhide:self.link];
		self.link.hidden = NO;
	}
	else
	{
		self.link.hidden = YES;
		[[TGRedditClient sharedClient] hide:self.link];
	}
	
	[self updateHideButton];
}

- (IBAction)reportPostPressed:(id)sender
{
	NSLog(@"Reprot post");
	// TODO API call with success&failure blocks
}

- (IBAction)sharePostPressed:(id)sender
{
	TUSafariActivity *safariActivity = [TUSafariActivity new];
	UIActivityViewController *shareSheet = [[UIActivityViewController alloc]
											initWithActivityItems:@[self.link.title, self.link.url]
											applicationActivities:@[safariActivity]];
	
	shareSheet.popoverPresentationController.barButtonItem = self.sharePostButton;
	
	[self presentViewController:shareSheet
					   animated:YES
					 completion:nil];
}

- (IBAction)upvoteButtonPressed:(id)sender
{
	if (self.link.isUpvoted)
	{
		self.link.voteStatus = TGVoteStatusNone;
		[[TGRedditClient sharedClient] vote:self.link direction:TGVoteStatusNone];
	}
	else
	{
		self.link.voteStatus = TGVoteStatusUpvoted;
		[[TGRedditClient sharedClient] vote:self.link direction:TGVoteStatusUpvoted];
	}
	
	[self updateVoteButtons];
}

- (IBAction)downvoteButtonPressed:(id)sender
{
	if (self.link.isDownvoted)
	{
		self.link.voteStatus = TGVoteStatusNone;
		[[TGRedditClient sharedClient] vote:self.link direction:TGVoteStatusNone];
	}
	else
	{
		self.link.voteStatus = TGVoteStatusDownvoted;
		[[TGRedditClient sharedClient] vote:self.link direction:TGVoteStatusDownvoted];
	}
	
	[self updateVoteButtons];
}

- (void) singleSwipeLeft: (UIGestureRecognizer *)sender
{
	NSIndexPath *indexPath = [self.commentTableView indexPathForRowAtPoint:[sender locationInView:self.commentTableView]];
	if (!indexPath) return; // swiped somewhere that wasn't a cell
	
	[self collapseOrExpandCommentsAtIndexPath:indexPath];
}

- (void) doubleSwipeLeft: (UIGestureRecognizer *)sender
{
	NSIndexPath *indexPath = [self.commentTableView indexPathForRowAtPoint:[sender locationInView:self.commentTableView]];
	if (!indexPath) return; // swiped somewhere that wasn't a cell
	
	NSIndexPath *rootIndexPath = [self indexPathAtRootOfIndentationTree:indexPath];
	[self collapseOrExpandCommentsAtIndexPath:rootIndexPath];
}

#pragma mark - TableView


- (void) reloadCommentTableViewData
{
	[self.commentTableView beginUpdates];
	[self.commentTableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
	[self.commentTableView endUpdates];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section) {
		case 0: return 1;
		case 1: return self.comments.count;
		default: return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch(indexPath.section) {
		case 0:
			self.postHeader = [self postHeaderCell];
			return self.postHeader;
		case 1:
			return [self commentCellAtIndexPath:indexPath];
		default:
			return nil;
	}
}

- (TGLinkPostCell *) postHeaderCell
{
	if (self.postHeader) return self.postHeader;
	
	TGLinkPostCell *cell = [self.commentTableView dequeueReusableCellWithIdentifier:@"TGLinkPostCell"];
	[self configureHeaderCell:cell];
		
	return cell;
}

- (void) configureHeaderCell:(TGLinkPostCell *)cell
{
	[self updateVoteButtons]; // TODO why is this not working
	
	// clear the delegates to prevent crashes — TODO solve?
	cell.title.delegate = self;
	cell.content.delegate = self;
	cell.metadata.delegate = self;
	
	// title
	cell.title.text = self.link.title;
	NSMutableAttributedString *mutAttrTitle = [cell.title.attributedText mutableCopy];
	NSDictionary *attributes;
	if ([self.link isSelfpost])
		attributes = @{NSForegroundColorAttributeName	: [ThemeManager colorForKey:kTGThemeTextColor] };
	else
		attributes = @{NSForegroundColorAttributeName	: [ThemeManager colorForKey:kTGThemeTintColor],
					   NSLinkAttributeName				: self.link.url };
	[mutAttrTitle addAttributes:attributes range:NSMakeRange(0, mutAttrTitle.length)];
	cell.title.attributedText = mutAttrTitle;
	
	// body/link content
	if (self.embeddedMediaType == EmbeddedMediaTweet)
	{
		[cell.content removeFromSuperview];
		TGTweetView *tweetView = [TGTweetView new];
		
		// configure tweetView // TODO move to [TGTweetView awakeFromNib] or similar?
		tweetView.layer.cornerRadius = 4.0f;
		tweetView.layer.borderColor = [[ThemeManager colorForKey:kTGThemeSeparatorColor] CGColor];
		tweetView.layer.borderWidth = 1.0f / [[UIScreen mainScreen] scale];
		tweetView.backgroundColor = [ThemeManager colorForKey:kTGThemeFadedBackgroundColor];
		
		[self configureTweetView:tweetView];
		
		// layout
		tweetView.translatesAutoresizingMaskIntoConstraints = NO;
		[cell.contentContainerView addSubview:tweetView];
		NSDictionary *views = NSDictionaryOfVariableBindings(tweetView);
		[cell.contentContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tweetView]|" options:0 metrics:nil views:views]];
		[cell.contentContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tweetView]|" options:0 metrics:nil views:views]];
	}
	else if ([self.link isSelfpost] && !([self.link.selfTextHTML isEqualToString:@""])) // if selfpost and has selftext
	{
//		cell.content.textColor = [ThemeManager colorForKey:kTGThemeTextColor];
		
		NSAttributedString *attrBody = [self.cachedAttributedStrings objectForKey:self.link.id]; // if cached, use that
		if (!attrBody) // else create new one and cache it
		{
//			attrBody = [TGRedditMarkdownParser attributedStringFromMarkdown:self.link.selfText];
			
			attrBody = [TGRedditMarkdownParser attributedStringFromHTML:self.link.selfTextHTML];
			
			[self.cachedAttributedStrings setObject:attrBody forKey:self.link.id];
		}
		cell.content.attributedText = attrBody;
	}
	else
	{
		cell.content.textColor = [ThemeManager colorForKey:kTGThemeSecondaryTextColor];
		cell.content.text = [self.link.url absoluteString];
		cell.content.dataDetectorTypes = UIDataDetectorTypeNone;
	}
	
	// metadata
	// subreddit link attributed substring
	NSURL *subredditURL = [[TGRedditClient sharedClient] urlToSubreddit:self.link.subreddit];
	NSString *subredditString = [NSString stringWithFormat:@"/r/%@", self.link.subreddit];
	attributes = @{NSForegroundColorAttributeName	: [ThemeManager colorForKey:kTGThemeTintColor],
				   NSFontAttributeName				: [UIFont fontWithName:@"AvenirNext-Medium" size:15.0],
				   NSLinkAttributeName				: subredditURL};
	NSAttributedString *subredditLink = [[NSAttributedString alloc] initWithString:subredditString attributes:attributes];
	// created timestamp
	NSString *created = [self.link.creationDate relativeDateString];
	if (![created isEqualToString:kRelativeDateStringSuffixJustNow]) created = [created stringByAppendingString:@" ago"];
	// edited timestamp
	NSString *edited = @"";
	if ([self.link isEdited])
	{
		NSString *relativeEditDateString = [self.link.editDate relativeDateString];
		if (![relativeEditDateString isEqualToString:kRelativeDateStringSuffixJustNow]) relativeEditDateString = [relativeEditDateString stringByAppendingString:@" ago"];
		edited = [NSString stringWithFormat:@" (edit %@)", relativeEditDateString]; // TODO better edit indicator
	}
	
	cell.metadata.textColor = [ThemeManager colorForKey:kTGThemeSecondaryTextColor];
	cell.metadata.text = [NSString stringWithFormat:@"%ld points in ", (long)self.link.score];
	NSMutableAttributedString *mutAttrMetadata = [cell.metadata.attributedText mutableCopy];
	[mutAttrMetadata appendAttributedString:subredditLink];
	cell.metadata.text = [NSString stringWithFormat:@" %@%@, by /u/%@", created, edited, self.link.author];
	[mutAttrMetadata appendAttributedString:cell.metadata.attributedText];
	
	cell.metadata.attributedText = mutAttrMetadata;
	
	// comments section header
	cell.numComments.text = [NSString stringWithFormat:@"%lu COMMENTS", (unsigned long)self.link.totalComments];
	[ThemeManager styleSmallcapsHeader:cell.numComments];
	
	cell.separator.backgroundColor = [ThemeManager colorForKey:kTGThemeBackgroundColor];
	cell.backgroundColor = [ThemeManager colorForKey:kTGThemeContentBackgroundColor];
	
	if (self.isImagePost)// add border to top of postHeaderCell
	{
		UIBezierPath *path = [UIBezierPath bezierPath];
		[path moveToPoint:CGPointMake(0, 0)];
		[path addLineToPoint:CGPointMake(self.view.frame.size.width, 0)]; // TODO why cell.bounds.size.width == 40 here; temp using self.view instead
		[path closePath];
		
		CAShapeLayer *shapeLayer = [CAShapeLayer layer];
		shapeLayer.path = [path CGPath];
		shapeLayer.strokeColor = [[[ThemeManager colorForKey:kTGThemeImageOverlayBorderColor] colorWithAlphaComponent:0.08f] CGColor];
		shapeLayer.lineWidth = 1.0f;
		
		shapeLayer.position = CGPointMake(0, 0);
		[cell.layer addSublayer:shapeLayer];
	}
}

- (TGCommentTableViewCell *)commentCellAtIndexPath:(NSIndexPath *)indexPath
{
	TGCommentTableViewCell *cell = [self.commentTableView dequeueReusableCellWithIdentifier:@"TGCommentTableViewCell" forIndexPath:indexPath];
	[self configureCommentCell:cell atIndexPath:indexPath];
	
	return cell;
}

- (void)configureCommentCell:(TGCommentTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	TGComment *comment = self.comments[indexPath.row];
	
	cell.bodyLabel.delegate = self;	// re-set the delegate *before* setting attrText to prevent null delegate crash
	
	if ([self.collapsedComments containsObject:comment])
	{
		NSString *collapsedText = [NSString stringWithFormat:@"Swipe to expand comment and %lu children", (unsigned long) comment.numberOfChildrenRecursively];
		NSDictionary *collapsedTextAttributes =
		@{NSForegroundColorAttributeName	: [ThemeManager colorForKey:kTGThemeSecondaryTextColor],
		  NSFontAttributeName				: [UIFont fontWithName:@"AvenirNext-MediumItalic" size:15.0]};
		cell.bodyLabel.attributedText = [[NSAttributedString alloc] initWithString:collapsedText attributes:collapsedTextAttributes];
	}
	else
	{
		NSAttributedString *attrBody = [self.cachedAttributedStrings objectForKey:comment.id]; // if cached, use that
		if (!attrBody) // else create new one and cache it
		{
//			attrBody = [TGRedditMarkdownParser attributedStringFromMarkdown:comment.body];
			
			attrBody = [TGRedditMarkdownParser attributedStringFromHTML:comment.bodyHTML];
			
			[self.cachedAttributedStrings setObject:attrBody forKey:comment.id];
		}
		cell.bodyLabel.attributedText = attrBody;
	}
	
	[cell.authorLabel setText:comment.author];
	if ([comment.author isEqualToString:self.link.author])
	{
		cell.authorLabel.textColor = [ThemeManager colorForKey:kTGThemeTintColor];
		cell.authorLabel.text = [cell.authorLabel.text stringByAppendingString:@" (OP)"]; // TODO
	}
	else {
		cell.authorLabel.textColor = [ThemeManager colorForKey:kTGThemeTextColor];
	}
	
	[cell.pointsLabel setText:[NSString stringWithFormat:@"%ld points", (long)comment.score]];
	
	NSString *edited = [comment isEdited] ? [NSString stringWithFormat:@" (edit %@)", [comment.editDate relativeDateString]] : @""; // TODO better edit indicator
	[cell.timestampLabel setText:[NSString stringWithFormat:@"%@%@", [comment.creationDate relativeDateString], edited]];
	
	cell.indentationLevel = comment.indentationLevel;
	
	cell.pointsLabel.textColor = [ThemeManager colorForKey:kTGThemeSecondaryTextColor];
	cell.timestampLabel.textColor = [ThemeManager colorForKey:kTGThemeSecondaryTextColor];
	
	if ([self.collapsedComments containsObject:comment]) cell.collapsed = YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch(indexPath.section) {
		case 0: return [self heightForHeaderCell];
		case 1: return [self heightForCommentCellAtIndexPath:indexPath];
		default: return 0;
	}
}

- (CGFloat)heightForHeaderCell
{
	if (self.postHeaderHeight != 0) return self.postHeaderHeight;
	
	static TGLinkPostCell *sizingCell = nil;
//	static dispatch_once_t onceToken;
//	dispatch_once(&onceToken, ^{
		sizingCell = [self.commentTableView dequeueReusableCellWithIdentifier:@"TGLinkPostCell"];
//	});
	
	[self configureHeaderCell:sizingCell];
	
	sizingCell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.commentTableView.frame), CGRectGetHeight(sizingCell.bounds));
	
	// constrain contentView.width to same as table.width
	// required for correct height calculation with UITextView
	// http://stackoverflow.com/questions/27064070/
	UIView *contentView = sizingCell.contentView;
	contentView.translatesAutoresizingMaskIntoConstraints = NO;
	NSDictionary *metrics = @{@"tableWidth":@(self.commentTableView.frame.size.width)};
	NSDictionary *views = NSDictionaryOfVariableBindings(contentView);
	[contentView addConstraints:
	 [NSLayoutConstraint constraintsWithVisualFormat:@"[contentView(tableWidth)]"
											 options:0
											 metrics:metrics
											   views:views]];
	
	[sizingCell setNeedsLayout];
	[sizingCell layoutIfNeeded];
	CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
	
	self.postHeaderHeight = size.height + 1.0f; // Add 1.0f for the cell separator height
	return self.postHeaderHeight;
}

- (CGFloat)heightForCommentCellAtIndexPath:(NSIndexPath *)indexPath
{
	TGComment *comment = self.comments[indexPath.row];
	CGFloat height;
	if ((height = [[self.commentHeights objectForKey:comment.id] floatValue]))
	{
		return height; // if cached, return cached height
	}
	
	static TGCommentTableViewCell *sizingCell = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sizingCell = [self.commentTableView dequeueReusableCellWithIdentifier:@"TGCommentTableViewCell"];
	});
 
	[self configureCommentCell:sizingCell atIndexPath:indexPath];
	
	height = [self calculateHeightForConfiguredCommentCell:sizingCell];
	[self.commentHeights setValue:@(height) forKey:comment.id]; // cache it
	return height;
}

- (CGFloat)calculateHeightForConfiguredCommentCell:(TGCommentTableViewCell *)sizingCell
{
	sizingCell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.commentTableView.frame), CGRectGetHeight(sizingCell.bounds));
	
	// constrain contentView.width to same as table.width
	// required for correct height calculation with UITextView
	// http://stackoverflow.com/questions/27064070/
	UIView *contentView = sizingCell.contentView;
	contentView.translatesAutoresizingMaskIntoConstraints = NO;
	NSDictionary *metrics = @{@"tableWidth":@(self.commentTableView.frame.size.width)};
	NSDictionary *views = NSDictionaryOfVariableBindings(contentView);
	[contentView addConstraints:
	 [NSLayoutConstraint constraintsWithVisualFormat:@"[contentView(tableWidth)]"
											 options:0
											 metrics:metrics
											   views:views]];
	
	[sizingCell setNeedsLayout];
	[sizingCell layoutIfNeeded];
	CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
	
	return size.height + 1.0f; // Add 1.0f for the cell separator height
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch(indexPath.section) {
		case 0:
		{
			if (self.link.isSelfpost) [tableView deselectRowAtIndexPath:indexPath animated:NO];
			else
			{
				[tableView deselectRowAtIndexPath:indexPath animated:YES];
				[self performSegueWithIdentifier:@"linkViewToWebView" sender:self];
				// TODO stop comments header BG gettign highlighted
			}
			break;
		}
		case 1:
		{
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
			[self collapseOrExpandCommentsAtIndexPath:indexPath];
			break;
		}
	}
}

- (NSIndexPath *) indexPathAtRootOfIndentationTree:(NSIndexPath *)indexPathInTree
{
	NSIndexPath *rootIndex = indexPathInTree;
	
	NSInteger row = indexPathInTree.row;
	TGComment *currentComment = self.comments[row];
	while (currentComment.indentationLevel != 0)
	{
		row--;
		currentComment = self.comments[row];
	}
	
	rootIndex = [NSIndexPath indexPathForRow:row inSection:indexPathInTree.section];
	return rootIndex;
}

- (void) collapseOrExpandCommentsAtIndexPath:(NSIndexPath *)indexPath
{
	TGComment *rootComment = self.comments[indexPath.row];
	if ([self.collapsedComments containsObject:rootComment])	[self expandCommentsAtIndexPath:indexPath];
	else															[self collapseCommentsAtIndexPath:indexPath];
}

- (void) collapseCommentsAtIndexPath:(NSIndexPath *)indexPath
{
	TGComment *rootComment = self.comments[indexPath.row];
	TGCommentTableViewCell *rootCell = (TGCommentTableViewCell *) [self.commentTableView cellForRowAtIndexPath:indexPath];
	
	// not yet collapsed; collapse it and remove its children
	[self.collapsedComments addObject:rootComment];
	rootCell.collapsed = YES;
	[self.commentHeights removeObjectForKey:rootComment.id]; // invalidate cached height
	
	NSMutableArray *children = [[TGComment childrenRecursivelyForComment:rootComment] mutableCopy];
	NSMutableArray *objectsToRemove = [NSMutableArray new];
	NSMutableArray *indexesToRemove = [NSMutableArray new];
	NSInteger skippedChildren = 0; // no. children skipped due to being collapsed under another collapse
	for (int i=0; i + skippedChildren < children.count; i++)
	{
		// add each child and its index to objectsToRemove and indexesToRemove
		TGComment *comment = children[i+skippedChildren];
		[objectsToRemove addObject:comment];
		[indexesToRemove addObject:[NSIndexPath indexPathForRow:indexPath.row+i+1 inSection:indexPath.section]];
		
		// if this child is root of (another) collapse, skip its children
		if ([self.collapsedComments containsObject:comment]) skippedChildren += comment.numberOfChildrenRecursively;
	}
	
	[self.commentTableView beginUpdates];
	[self.comments removeObjectsInArray:objectsToRemove];
	[self.commentTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade]; // reload rootCell because height changed
	[self.commentTableView deleteRowsAtIndexPaths:indexesToRemove withRowAnimation:UITableViewRowAnimationFade];
	[self.commentTableView endUpdates];
}

- (void) expandCommentsAtIndexPath:(NSIndexPath *)indexPath
{
	TGComment *rootComment = self.comments[indexPath.row];
	TGCommentTableViewCell *rootCell = (TGCommentTableViewCell *) [self.commentTableView cellForRowAtIndexPath:indexPath];
	
	[self.collapsedComments removeObject:rootComment];
	rootCell.collapsed = NO;
	[self.commentHeights removeObjectForKey:rootComment.id]; // invalidate cached height
	
	NSMutableArray *children = [[TGComment childrenRecursivelyForComment:rootComment] mutableCopy];
	NSMutableArray *indexesToAdd = [NSMutableArray new];
	NSMutableArray *objectsToAdd = [NSMutableArray new];
	NSInteger skippedChildren = 0; // no. children skipped due to being collapsed under another collapse
	for (int i=0; i + skippedChildren < children.count; i++)
	{
		// add each child and its index to objectsToAdd and indexesToAdd
		TGComment *comment = children[i+skippedChildren];
		[objectsToAdd addObject:comment];
		[indexesToAdd addObject:[NSIndexPath indexPathForRow:indexPath.row+i+1 inSection:indexPath.section]];
		
		// if this child is root of (another) collapse, skip its children
		if ([self.collapsedComments containsObject:comment]) skippedChildren += comment.numberOfChildrenRecursively;
	}
	
	[self.commentTableView beginUpdates];
	NSIndexSet *indexSetToAdd = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(indexPath.row+1, indexesToAdd.count)];
	[self.comments insertObjects:objectsToAdd atIndexes:indexSetToAdd];
	[self.commentTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade]; // reload rootCell because height changed
	[self.commentTableView insertRowsAtIndexPaths:indexesToAdd withRowAnimation:UITableViewRowAnimationFade];
	[self.commentTableView endUpdates];
}

#pragma mark - UIScrollView

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (!self.isImagePost) return; // don't do anything if we're not an imagePost
	
	[self updatePreviewImageSizeBasedOnScrollView:scrollView];
	
	CGFloat const scrollThreshold = -44.0f; // when scrollView content is toolbar height away from top of screen
	CGFloat alpha = (scrollView.contentOffset.y > scrollThreshold) ? 1.0f : 0.0f;
	[UIView animateWithDuration:0.3f animations:^{
		[self setToolbarAlpha:alpha]; // TODO test performance of calling this on every scrollViewDidScroll instead of determining whether necessary *here* instead of inside -setToolbarAlpha:
	}];
	
	/*
	 CGFloat offsetY = scrollView.contentOffset.y;
	 CGFloat const transformDistance = 20.0f;
	 CGFloat const scrollThreshold = self.previewImageHeight.constant - 44.0f - transformDistance;
	 if (offsetY > scrollThreshold)
	 {
		CGFloat progress = 1 - ((scrollThreshold + transformDistance - offsetY) / transformDistance); // 0.0 to 1.0
		[self setToolbarAlpha:progress];
	 }
	 else [self setToolbarAlpha:0.0];
	 */
}

- (void) updatePreviewImageSizeBasedOnScrollView:(UIScrollView *)scrollView
{
	CGFloat yOffset = scrollView.contentOffset.y;
	if (yOffset > 0) return;
	
	CGRect frame = self.previewImage.frame;
	
	if (yOffset > -self.previewImageHeight.constant)
	{
		frame.origin.y = - ((self.previewImageHeight.constant + yOffset) / 2);
	}
	else
	{
		frame.origin.y = 0;
		frame.size.height = -yOffset;
	}
	
	self.previewImage.frame = frame;
}

#pragma mark - UITextView

- (BOOL) textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
	self.interactedURL = URL;
	
	if ([self.interactedURL.scheme isEqualToString:[[TGRedditClient sharedClient] uriScheme]])
	{
		[self dismissViewControllerAnimated:YES completion:nil];
		return YES; // let application delegate handle it
	}
	else
	{
		if ([URL isEqual:self.link.url])	[self performSegueWithIdentifier:@"linkViewToWebView" sender:self];
		else								[self performSegueWithIdentifier:@"openLink" sender:self];
		return NO;
	}
}

#pragma mark - UIBarPosition

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
	if (bar == self.topToolbar) return UIBarPositionTop;
	
	return UIBarPositionTop;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"linkViewToWebView"])
	{
		TGWebViewController *webVC = segue.destinationViewController;
		webVC.link = self.link;
	}
	else if ([segue.identifier isEqualToString:@"openLink"])
	{
		TGWebViewController *webVC = segue.destinationViewController;
		webVC.url = self.interactedURL;
	}
}

#pragma mark - Controller Transitioning

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
	if (presented == self) return [[TGFormAnimationController alloc] initPresenting:YES];
	else return nil;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
	if (dismissed == self) return [[TGFormAnimationController alloc] initPresenting:NO];
	else return nil;
}

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented
													  presentingViewController:(UIViewController *)presenting
														  sourceViewController:(UIViewController *)source
{
	if (presented == self) return [[TGFormPresentationController alloc] initWithPresentedViewController:presented
																			   presentingViewController:presenting];
	else return nil;
}

#pragma mark - Utility

- (void) commentsFromResponse:(NSArray *)responseArray	// TODO move this into the MODEL - tgredditclient
{
	NSMutableArray *comments = [NSMutableArray new];
	
	for (id dict in responseArray)
	{
		TGComment *comment = [[TGComment new] initCommentFromDictionary:dict];
		
		if (comment)
		{
			[comments addObject:comment];
			comments = [[comments arrayByAddingObjectsFromArray:[TGComment childrenRecursivelyForComment:comment]] mutableCopy];
		}
	}
	
	NSMutableArray *indexPaths = [NSMutableArray new];
	for (int i=0; i < comments.count; i++)
		[indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:1]];
	
	[self.commentTableView beginUpdates];
	self.originalComments = [NSArray arrayWithArray:comments];
	[self.commentTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	[self.commentTableView endUpdates];
	
	NSLog(@"Found %lu comments", (unsigned long)self.comments.count);
}

- (BOOL) toolbarIsTransparent
{
	CGFloat currentAlpha;
	[self.topToolbar.backgroundColor getWhite:nil alpha:&currentAlpha];
	
	return (currentAlpha < 1.0f);
}

@end