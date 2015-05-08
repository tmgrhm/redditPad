//
//  TGPostViewController.m
//  redditPad
//
//  Created by Tom Graham on 23/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGPostViewController.h"

#import "ThemeManager.h"

#import "TGRedditClient.h"
#import "TGComment.h"
#import "TGMoreComments.h"

#import "TGCommentTableViewCell.h"
#import "TGWebViewController.h"
#import "TGLinkPostCell.h"

#import "NSDate+RelativeDateString.h"

#import "TGFormPresentationController.h"
#import "TGFormAnimationController.h"

#import <XNGMarkdownParser/XNGMarkdownParser.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <TUSafariActivity/TUSafariActivity.h>

@interface TGPostViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (weak, nonatomic) IBOutlet UITableView *commentTableView;
@property (weak, nonatomic) IBOutlet UIToolbar *topToolbar;
@property (weak, nonatomic) IBOutlet UIImageView *previewImage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewImageHeight;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *savePostButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *hidePostButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sharePostButton;

@property (nonatomic) CGFloat postHeaderHeight;
@property (strong, nonatomic) TGLinkPostCell *postHeader;

@property (strong, nonatomic) NSArray *originalComments; // original comments as returned from API
@property (strong, nonatomic) NSMutableArray *comments; // comments to display (excluding collapsed children)
@property (strong, nonatomic) NSMutableArray *collapsedComments; // comments at the root of a collapse
@property (strong, nonatomic) NSMutableDictionary *commentHeights;
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
	self.collapsedComments = [NSMutableArray new];
	self.commentHeights = [NSMutableDictionary new];
}

- (void)viewDidLoad {
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
	self.containerView.backgroundColor = [ThemeManager backgroundColor];
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

- (void) updateSaveButton
{
	// TODO get colours working properly
	self.savePostButton.tintColor = self.link.isSaved ? [ThemeManager saveColor] : [ThemeManager inactiveColor];
}

- (void) updateHideButton
{
	if (self.link.isHidden)
	{
		self.hidePostButton.image = [UIImage imageNamed:@"Icon-Post-Hide-Active"];	// TODO consts?
		self.hidePostButton.tintColor = [ThemeManager tintColor];					// TODO not working
	} else {
		self.hidePostButton.image = [UIImage imageNamed:@"Icon-Post-Hide-Inactive"];
		self.hidePostButton.tintColor = [ThemeManager inactiveColor];
	}
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

- (IBAction)hidePostPressed:(id)sender {
	NSLog(@"Hide post");
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

- (IBAction)reportPostPressed:(id)sender {
	NSLog(@"Reprot post");
	// TODO API call with success&failure blocks
}

- (IBAction)sharePostPressed:(id)sender {
	TUSafariActivity *safariActivity = [TUSafariActivity new];
	UIActivityViewController *shareSheet = [[UIActivityViewController alloc]
											initWithActivityItems:@[self.link.title, self.link.url]
											applicationActivities:@[safariActivity]];
	
	shareSheet.popoverPresentationController.barButtonItem = self.sharePostButton;
	
	[self presentViewController:shareSheet
					   animated:YES
					 completion:nil];
}

- (IBAction)upvoteButtonPressed:(id)sender {
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

- (IBAction)downvoteButtonPressed:(id)sender {
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
	[self collapseOrExpandCommentsAtIndexPath:indexPath];
}

- (void) doubleSwipeLeft: (UIGestureRecognizer *)sender
{
	NSIndexPath *indexPath = [self.commentTableView indexPathForRowAtPoint:[sender locationInView:self.commentTableView]];
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
	
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	
	return cell;
}

- (void) configureHeaderCell:(TGLinkPostCell *)cell
{
	// image-specific stuff
	if (self.link.isImageLink)
	{
		self.topToolbar.tintColor = [UIColor whiteColor];
		[self.topToolbar setBackgroundImage:[UIImage new]
						 forToolbarPosition:UIBarPositionAny
								 barMetrics:UIBarMetricsDefault];
		[self.topToolbar setShadowImage:[UIImage new]
					 forToolbarPosition:UIToolbarPositionAny];
		
		[self.previewImage setImageWithURL:self.link.url];
		self.previewImageHeight.constant = 300;
		cell.topMargin.constant = 200;
		
		// TODO add shadow to topToolbar buttons
	}
	else
	{
		self.topToolbar.layer.borderColor = [[ThemeManager separatorColor] CGColor];
		self.topToolbar.layer.borderWidth = 1.0f / [[UIScreen mainScreen] scale];
		
		self.previewImage.image = nil;
		self.previewImageHeight.constant = 0;
		cell.topMargin.constant = 0;
	}
	
	[self updateSaveButton];
	[self updateHideButton];
	[self updateVoteButtons];
	
	// clear the delegates to prevent crashes — TODO solve?
	cell.title.delegate = self;
	cell.content.delegate = self;
	cell.metadata.delegate = self;
	
	// title
	cell.title.text = self.link.title;
	NSMutableAttributedString *mutAttrTitle = [cell.title.attributedText mutableCopy];
	NSDictionary *attributes;
	if ([self.link isSelfpost])
		attributes = @{NSForegroundColorAttributeName	: [ThemeManager textColor] };
	else
		attributes = @{NSForegroundColorAttributeName	: [ThemeManager tintColor],
					   NSLinkAttributeName				: self.link.url};
	[mutAttrTitle addAttributes:attributes range:NSMakeRange(0, mutAttrTitle.length)];
	cell.title.attributedText = mutAttrTitle;
	
	// content
	if ([self.link isSelfpost])
	{
		cell.content.textColor = [ThemeManager textColor];
		cell.content.attributedText = [self attributedStringFromMarkdown:self.link.selfText];
	} else {
		cell.content.textColor = [ThemeManager secondaryTextColor];
		cell.content.text = [self.link.url absoluteString];
		cell.content.dataDetectorTypes = UIDataDetectorTypeNone;
	}
	
	// metadata
	NSURL *subredditURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://showSubreddit?name=%@", [TGRedditClient uriScheme], self.link.subreddit]];
	NSString *subredditString = [NSString stringWithFormat:@"/r/%@", self.link.subreddit];
	attributes = @{NSForegroundColorAttributeName	: [ThemeManager tintColor],
				   NSFontAttributeName				: [UIFont fontWithName:@"AvenirNext-Medium" size:15.0],
				   NSLinkAttributeName				: subredditURL};
	NSAttributedString *subredditLink = [[NSAttributedString alloc] initWithString:subredditString attributes:attributes];
	
	NSString *edited = [self.link isEdited] ? [NSString stringWithFormat:@" (edited %@)", [self.link.editDate relativeDateString]] : @""; // TODO better edit indicator
	
	cell.metadata.textColor = [ThemeManager secondaryTextColor];
	cell.metadata.text = [NSString stringWithFormat:@"%ld points in ", (long)self.link.score];
	
	NSMutableAttributedString *mutAttrMetadata = [cell.metadata.attributedText mutableCopy];
	[mutAttrMetadata appendAttributedString:subredditLink];
	
	cell.metadata.text = [NSString stringWithFormat:@" %@%@ ago, by %@", [self.link.creationDate relativeDateString], edited, self.link.author];
	[mutAttrMetadata appendAttributedString:cell.metadata.attributedText];
	
	cell.metadata.attributedText = mutAttrMetadata;
	
	// comments section header
	cell.numComments.text = [NSString stringWithFormat:@"%lu COMMENTS", (unsigned long)self.link.totalComments];
	[ThemeManager styleSmallcapsHeader:cell.numComments];
	
	cell.separator.backgroundColor = [ThemeManager backgroundColor];
	cell.backgroundColor = [UIColor clearColor];
	cell.mainBackground.backgroundColor = [ThemeManager contentBackgroundColor];
}

- (TGCommentTableViewCell *)commentCellAtIndexPath:(NSIndexPath *)indexPath
{
	TGCommentTableViewCell *cell = [self.commentTableView dequeueReusableCellWithIdentifier:@"TGCommentTableViewCell" forIndexPath:indexPath];
	[self configureCommentCell:cell atIndexPath:indexPath];
	
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	
	return cell;
}

- (void)configureCommentCell:(TGCommentTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	TGComment *comment = self.comments[indexPath.row];
	
	cell.bodyLabel.delegate = self;	// re-set the delegate *before* setting attrText to prevent null delegate crash
	
	if ([self.collapsedComments containsObject:comment])
	{
		NSString *collapsedText = [NSString stringWithFormat:@"Swipe to expand comment and %lu children", comment.numberOfChildrenRecursively];
		NSDictionary *collapsedTextAttributes =
	  @{NSForegroundColorAttributeName	: [ThemeManager secondaryTextColor],
		NSFontAttributeName				: [UIFont fontWithName:@"AvenirNext-MediumItalic" size:15.0]};
		cell.bodyLabel.attributedText = [[NSAttributedString alloc] initWithString:collapsedText attributes:collapsedTextAttributes];
	}
	else
	{
		NSAttributedString *attrBody = [self attributedStringFromMarkdown:comment.body];
		[cell.bodyLabel setAttributedText:attrBody];
	}
	
	[cell.authorLabel setText:comment.author];
	if ([comment.author isEqualToString:self.link.author])
	{
		cell.authorLabel.text = [cell.authorLabel.text stringByAppendingString:@" (OP)"]; // TODO
		cell.authorLabel.textColor = [ThemeManager tintColor];
	} else {
		cell.authorLabel.textColor = [ThemeManager textColor];
	}
	
	[cell.pointsLabel setText:[NSString stringWithFormat:@"%ld points", (long)comment.score]];
	
	NSString *edited = [comment isEdited] ? [NSString stringWithFormat:@" (edited %@)", [comment.editDate relativeDateString]] : @""; // TODO better edit indicator
	[cell.timestampLabel setText:[NSString stringWithFormat:@"%@%@", [comment.creationDate relativeDateString], edited]];
	
	cell.indentationLevel = comment.indentationLevel;
	
	cell.pointsLabel.textColor = [ThemeManager secondaryTextColor];
	cell.timestampLabel.textColor = [ThemeManager secondaryTextColor];
	
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
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sizingCell = [self.commentTableView dequeueReusableCellWithIdentifier:@"TGLinkPostCell"];
	});

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
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
/*	switch(indexPath.section) {
		case 0:
			[tableView deselectRowAtIndexPath:indexPath animated:NO];
			// TODO header tapped
			break;
		case 1:
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
			[self collapseCommentsAtIndexPath:indexPath];
			break;
	}*/
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

#pragma mark - UITextView
- (BOOL) textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
	self.interactedURL = URL;
	
	if ([URL.scheme isEqualToString:[TGRedditClient uriScheme]])
	{
		[self dismissViewControllerAnimated:YES completion:nil];
		return YES; // let application delegate handle it
	}
	else
	{
		[self performSegueWithIdentifier:@"openLink" sender:self];
		return NO;
	}
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

- (NSAttributedString *) attributedStringFromMarkdown:(NSString *)markdown
{
	// remove trailing newlines
	NSString *newMarkdown = markdown;
	while ([newMarkdown hasSuffix:@"\n"])
		newMarkdown = [newMarkdown substringToIndex:newMarkdown.length-1];
	// replace 2+ consecutive returns with single new paragraphs
	while ([newMarkdown rangeOfString:@"\n\n"].location != NSNotFound)
	{
		newMarkdown = [newMarkdown stringByReplacingOccurrencesOfString:@"\n\n" withString:@"\n"];
	}
	markdown = newMarkdown;
	
	XNGMarkdownParser *parser = [XNGMarkdownParser new];
	parser.paragraphFont = [UIFont fontWithName:@"AvenirNext-Medium" size:15];
	parser.boldFontName = @"AvenirNext-DemiBold";
	parser.italicFontName = @"AvenirNext-MediumItalic";
	parser.boldItalicFontName = @"AvenirNext-DemiBoldItalic";
	parser.linkFontName = @"AvenirNext-DemiBold";
	parser.topAttributes = @{NSForegroundColorAttributeName : [ThemeManager textColor]};
	
	NSMutableAttributedString *string = [[parser attributedStringFromMarkdownString:markdown] mutableCopy]; // TODO I think XNG allows you to set paragraph style on the parser instead
	NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
	[paragraphStyle setMinimumLineHeight:21.0];
	[paragraphStyle setParagraphSpacing:6.0];
	
	[string addAttribute:NSParagraphStyleAttributeName
				   value:paragraphStyle
				   range:NSMakeRange(0, string.length)];
	
	return string;
}

@end
