//
//  FrontPageViewController.m
//  redditPad
//
//  Created by Tom Graham on 03/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "FrontPageViewController.h"

#import "TGListingTableViewCell.h"
#import "TGWebViewController.h"
#import "TGPostViewController.h"
#import "TGImageViewController.h"
#import "TGSearchViewController.h"
#import "TGSubredditInfoViewController.h"

#import "TGRedditClient.h"
#import "ThemeManager.h"

#import "NSDate+RelativeDateString.h"

#import <AFNetworking/UIImageView+AFNetworking.h>

@interface FrontPageViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sortControl;

@property (strong, nonatomic) NSMutableArray *listings;
@property (strong, nonatomic) NSMutableDictionary *listingCellHeights;
@property (strong, nonatomic) TGLink *selectedLink;

@end

@implementation FrontPageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
	self.listings = [NSMutableArray new];
	self.listingCellHeights = [NSMutableDictionary new];
	
	// TODO custom refreshControl
	self.refreshControl = [UIRefreshControl new];
	[self.refreshControl addTarget:self
					   action:@selector(refreshData)
			 forControlEvents:UIControlEventValueChanged];
	[self.tableView addSubview:self.refreshControl];
	
	[self configureNavigationBarTitle];
	
	[self themeAppearance];
	
	self.pagination = [TGPagination new];
	[self loadSubreddit:self.pagination.subreddit];
	
	[self scrollToTopWithAnimation:NO];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeDidChange) name:kThemeDidChangeNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup & Appearance

- (void) configureNavigationBarTitle
{
	UIView *titleView = [UIView new];
	
	UILabel *titleLabel = [UILabel new];
	titleLabel.text = [self titleFromPagination];
	
	NSMutableAttributedString *attrTitle = [titleLabel.attributedText mutableCopy];
	NSDictionary *attributes = @{NSForegroundColorAttributeName:[ThemeManager textColor],
								 NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-DemiBold" size:17.0f]};
	[attrTitle addAttributes:attributes range:NSMakeRange(0, attrTitle.length)];
	
	if (![self.pagination.subreddit isEqualToString:kSubredditFrontPage]) // title is not "Front Page"
	{
		// style leading `/r/`
		attributes = @{NSForegroundColorAttributeName:[ThemeManager secondaryTextColor],
					   NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Medium" size:17.0f]};
		[attrTitle addAttributes:attributes range:NSMakeRange(0, 3)];
		// trim trailing `/`
		attrTitle = [[attrTitle attributedSubstringFromRange:NSMakeRange(0, attrTitle.length-1)] mutableCopy];
	}
	titleLabel.attributedText = attrTitle;
	CGFloat titleLabelWidth = [titleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].width;
	titleLabel.frame = CGRectMake(0, 0, titleLabelWidth, 30);
	[titleView addSubview:titleLabel];
	
	CGFloat titleViewWidth = titleLabelWidth;
	
	if (![self.pagination.subreddit isEqualToString:kSubredditFrontPage]) // title is not "Front Page"
	{
		CGFloat padding = 4.0f;
		// create & add dropdownIndicator
		UIImageView *dropdownImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Icon-Navbar-TitleDropdown"]];
		CGFloat imageX = titleLabel.frame.size.width + titleLabel.frame.origin.x + padding;
		CGFloat imageY = ceilf((titleLabel.frame.size.height - dropdownImage.frame.size.height) / 2.0f);
		dropdownImage.frame = CGRectMake(imageX, imageY, dropdownImage.frame.size.width, dropdownImage.frame.size.height);
		
		[titleView addSubview:dropdownImage];
		titleViewWidth += dropdownImage.frame.size.width + padding;
		
		// create titleTapped gestureRecognizer
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(titleTapped)];
		titleView.userInteractionEnabled = YES;
		[titleView addGestureRecognizer:tapGesture];
	}
	
	titleView.frame = CGRectMake(0, 0, titleViewWidth, 30);
	
	self.navigationItem.titleView = titleView;
}

- (void) themeAppearance
{
	self.view.backgroundColor = [ThemeManager backgroundColor];
	
	self.refreshControl.backgroundColor = [UIColor clearColor];
	self.refreshControl.tintColor = [ThemeManager secondaryTextColor]; // TODO get better colour
}

- (void) themeDidChange
{
	NSLog(@"fpVC themeDidChange");
	[self themeAppearance];
	
	// TODO update self properly
	
	UINavigationBar *navbar = self.navigationController.navigationBar;
	navbar.barStyle = [ThemeManager uiBarStyle];
	navbar.barTintColor = [ThemeManager contentBackgroundColor];
	navbar.tintColor = [ThemeManager tintColor];
	
	self.sortControl.tintColor = [ThemeManager tintColor];
	[self.sortControl setTitleTextAttributes:@{NSForegroundColorAttributeName:[ThemeManager contentBackgroundColor]} forState:UIControlStateSelected];
	
	self.tableView.backgroundColor = [ThemeManager backgroundColor];
	[self reloadTableView];
}

#pragma mark - IBAction

- (void)refreshData	// pull-to-refresh
{
	[self loadSubredditWithCurrentPagination];
}

- (IBAction)sortChanged:(UISegmentedControl *)sender
{
	NSString *sortString = [sender titleForSegmentAtIndex:sender.selectedSegmentIndex];		// TODO better conversion
	if ([sortString isEqualToString:@"Controv."])	sortString = @"Controversial";			// TODO better conversion
	
	NSString *subreddit = self.pagination.subreddit;
	self.pagination = [TGPagination new];
	self.pagination.subreddit = subreddit;
	self.pagination.sort = [TGSubreddit sortFromSortString:sortString];
	self.pagination.timeframe = 0;
	
	if (self.pagination.sort == TGSubredditSortTop || self.pagination.sort == TGSubredditSortControversial)
	{
		[self showSortTimeframePicker];
	}
	else // don't need timeframe otherwise, can make call now
	{
		[self loadSubredditWithCurrentPagination];
	}
}

- (void) showSortTimeframePicker	// TODO
{
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:nil
																	  preferredStyle:UIAlertControllerStyleActionSheet];
	[alertController setModalPresentationStyle:UIModalPresentationPopover];
	
	NSArray *sortTypes = @[kTGSubredditSortTimeframeStringHour, kTGSubredditSortTimeframeStringDay, kTGSubredditSortTimeframeStringWeek, kTGSubredditSortTimeframeStringMonth, kTGSubredditSortTimeframeStringYear, kTGSubredditSortTimeframeStringAll];
	
	for (int i=0; i < sortTypes.count; i++)
	{
		[alertController addAction:[UIAlertAction actionWithTitle:sortTypes[i]
															style:UIAlertActionStyleDefault
														  handler:^(UIAlertAction *action) {
															  NSLog(@"action:%@", action.title);
															  self.pagination.timeframe = [TGSubreddit sortTimeframeFromSortString:action.title];
															  [self loadSubredditWithCurrentPagination];
														  }]];
	}
	
	UIPopoverPresentationController *popPresenter = [alertController
													 popoverPresentationController];
	popPresenter.sourceView = self.sortControl;
	popPresenter.sourceRect = self.sortControl.bounds;
	[self presentViewController:alertController animated:YES completion:nil];
	// TODO handle user tapping out of TimeframePicker popover — set sortControl back to what it was
}

- (void) titleTapped
{
	if (self.pagination.subreddit == kSubredditFrontPage) return; // don't show subredditInfo if frontpage
	
	[self performSegueWithIdentifier:@"listingToSubredditInfo" sender:self];
}

#pragma mark - Loading Data

- (void)loadSubreddit:(NSString *)subredditURL
{
	// clear current pagination
	self.sortControl.selectedSegmentIndex = 0;
	self.pagination = [TGPagination new];
	self.pagination.subreddit = subredditURL;
	
	[self configureNavigationBarTitle];
	
	[self loadSubredditWithCurrentPagination];
}

- (void) loadMore
{
	[self loadSubredditAfter:self.listings.lastObject];	// TODO handle no results case
}

- (void) loadSubredditAfter:(TGLink *)link
{
	NSLog(@"fpVC loadAfter: %@", link.fullname);
	self.pagination.afterLink = link;
	
	__weak __typeof(self)weakSelf = self;
	[[TGRedditClient sharedClient] requestSubredditWithPagination:self.pagination withCompletion:^(NSArray *collection, NSError *error)
	 {
		 if (error)
		 {
			 // TODO
		 } else
		 {
			 if (collection.count == 0) // no posts found after that post, probably because it's no longer in the current listing?
			 {
				 NSUInteger index = [self.listings indexOfObject:link];
				 [self loadSubredditAfter:self.listings[index-1]];
			 }
			 else
				 [weakSelf appendPosts:collection];
		 }
	 }];
}

- (void)loadSubredditWithCurrentPagination
{
	NSLog(@"fpVC.subreddit: %@", self.pagination.subreddit);
	__weak __typeof(self)weakSelf = self;
	[[TGRedditClient sharedClient] requestSubredditWithPagination:self.pagination withCompletion:^(NSArray *collection, NSError *error)
	 {
		 if (error)
		 {
			 // TODO
		 } else
		 {
			 [weakSelf setPosts:collection];
		 }
	 }];
}

- (void) setPosts:(NSArray *)posts
{
	[self.refreshControl endRefreshing];
	self.listings = [posts mutableCopy];
	[self reloadTableView];
}

- (void) appendPosts:(NSArray *)posts
{
	NSMutableArray *newPosts = [NSMutableArray array];
	NSMutableArray *indexPaths = [NSMutableArray array];
	
	for (int i=0; i < posts.count; i++)	// remove any posts already in listing
	{
		TGLink *currentNewPost = posts[i];
		BOOL isAlreadyInListing = NO;
		for (int j=0; (j < self.listings.count) && !isAlreadyInListing; j++)
		{
			TGLink *existingPost = self.listings[j];
			if ([existingPost.id isEqualToString:currentNewPost.id])
			{
				isAlreadyInListing = YES;
			}
		}
		if (!isAlreadyInListing)	[newPosts addObject:currentNewPost];
	}
	NSLog(@"appended %lu posts", (unsigned long)newPosts.count);
	
	NSInteger currentCount = self.listings.count;
	for (int i=0; i < newPosts.count; i++) {
		[indexPaths addObject:[NSIndexPath indexPathForRow:currentCount+i inSection:0]];
	}
	
	[self.tableView beginUpdates];
	[self.listings addObjectsFromArray:newPosts];
	[self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
	[self.tableView endUpdates];
}

#pragma mark - Subreddit Delegate (SVC)

- (void) didSelectSubreddit:(NSString *)subreddit
{
	[self loadSubreddit:subreddit];
	[self scrollToTopWithAnimation:YES];
}

#pragma mark - TableView

- (void) reloadTableView
{
	[self.tableView beginUpdates];
	[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic]; // TODO get good animation
	[self.tableView endUpdates];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.listings.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row == self.listings.count-10)
		[self loadMore];
	
	return [self listingCellAtIndexPath:indexPath];
}

- (TGListingTableViewCell *)listingCellAtIndexPath:(NSIndexPath *)indexPath
{
	TGListingTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"TGListingTableViewCell" forIndexPath:indexPath];
	[self configureListingCell:cell atIndexPath:indexPath];
	
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	
	return cell;
}

- (void)configureListingCell:(TGListingTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	TGLink *link = ((TGLink *)self.listings[indexPath.row]);
	
	cell.title.text = link.title;
	cell.score.text = [NSString stringWithFormat:@"%ld", (long)link.score];
	cell.subreddit.text = link.subreddit;
	cell.timestamp.text = [link.creationDate relativeDateString];
	cell.author.text = link.author;
	cell.totalComments.text = [NSString stringWithFormat:@"%lu", (unsigned long)link.totalComments];
	cell.commentsButton.tag = indexPath.row; // TODO better way
	
	if (link.thumbnailURL == nil) {
		[cell.thumbnail setImage:nil];
	} else {
		[cell.thumbnail setImageWithURL:link.thumbnailURL];
	}
	
	if (link.isSelfpost) {
		cell.domain.hidden = YES;
	} else {
		cell.domain.text = link.domain;
		cell.domain.hidden = NO;
	}
	
	if (link.isSticky)	// TODO
		cell.title.textColor = [ThemeManager stickyColor];
	else
		cell.title.textColor = [ThemeManager textColor];
	
	cell.upvoteIndicator.image = [UIImage imageNamed:@"Icon-Listing-Upvote-Inactive"];
	cell.downvoteIndicator.image = [UIImage imageNamed:@"Icon-Listing-Downvote-Inactive"];
	
	if (link.isUpvoted)
		cell.upvoteIndicator.image = [UIImage imageNamed:@"Icon-Listing-Upvote-Active"];		// TODO consts?
	else if (link.isDownvoted)
		cell.downvoteIndicator.image = [UIImage imageNamed:@"Icon-Listing-Downvote-Active"];
	
	cell.score.textColor = [ThemeManager secondaryTextColor];
	cell.timestamp.textColor = [ThemeManager secondaryTextColor];
	cell.author.textColor = [ThemeManager secondaryTextColor];
	cell.domain.textColor = [ThemeManager secondaryTextColor];
	cell.totalComments.textColor = [ThemeManager tintColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [self heightForListingCellAtIndexPath:indexPath];
}

- (CGFloat)heightForListingCellAtIndexPath:(NSIndexPath *)indexPath
{
	TGLink *link = self.listings[indexPath.row];
	CGFloat height;
	if ((height = [[self.listingCellHeights objectForKey:link.id] floatValue]))
	{
		return height; // if cached, return cached height
	}
	
	static TGListingTableViewCell *sizingCell = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sizingCell = [self.tableView dequeueReusableCellWithIdentifier:@"TGListingTableViewCell"];
	});
 
	[self configureListingCell:sizingCell atIndexPath:indexPath];
	
	height = [self calculateHeightForConfiguredListingCell:sizingCell];
	[self.listingCellHeights setValue:@(height) forKey:link.id]; // cache it
	return height;
}

- (CGFloat)calculateHeightForConfiguredListingCell:(TGListingTableViewCell *)sizingCell
{
	sizingCell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.tableView.frame), CGRectGetHeight(sizingCell.bounds));
	
	// constrain contentView.width to same as table.width
	// required for correct height calculation with UITextView
	// http://stackoverflow.com/questions/27064070/
	UIView *contentView = sizingCell.contentView;
	contentView.translatesAutoresizingMaskIntoConstraints = NO;
	NSDictionary *metrics = @{@"tableWidth":@(self.tableView.frame.size.width)};
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// When user selects a row
   [tableView deselectRowAtIndexPath:indexPath animated:TRUE];
	
	self.selectedLink = self.listings[indexPath.row];
	
/*	if ([self.selectedLink isImageLink])
	{
		[self performSegueWithIdentifier:@"listingToImageView" sender:self]; // TODO better imageView
	} else */
	if ([self.selectedLink isSelfpost])
	{
		[self performSegueWithIdentifier:@"listingToPostView" sender:self];
	}
	else
		[self performSegueWithIdentifier:@"listingToWebView" sender:self];
}

- (void) scrollToTopWithAnimation:(BOOL)animated
{
	[self.tableView setContentOffset:CGPointMake(0, 0 - self.tableView.contentInset.top + 66) animated:animated];
}

#pragma mark - Convenience

- (NSString *) titleFromPagination
{
	return [self.pagination.subreddit isEqualToString:kSubredditFrontPage] ? @"Front Page" : self.pagination.subreddit;
}

#pragma mark - Navigation

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"listingToPostView"])
	{
		TGPostViewController *linkVC = segue.destinationViewController;
		linkVC.transitioningDelegate = linkVC;
		linkVC.modalPresentationStyle = UIModalPresentationCustom;
		
		NSInteger indexPathRow = 0;
		if ([sender isKindOfClass:[UIButton class]])
		{
			UIButton *commentsButton = (UIButton *)sender;
			indexPathRow = commentsButton.tag;
			// TODO change how the row is identified
			// http://stackoverflow.com/questions/23784630/
			self.selectedLink = self.listings[indexPathRow];
		}
		linkVC.link = self.selectedLink;
	}
	else if ([segue.identifier isEqualToString:@"listingToWebView"])
	{
		TGWebViewController *webVC = segue.destinationViewController;
		webVC.link = self.selectedLink;
	}
	else if ([segue.identifier isEqualToString:@"listingToImageView"])
	{
		TGImageViewController *imageVC = segue.destinationViewController;
		imageVC.imageURL = self.selectedLink.url;
	}
	else if ([segue.identifier isEqualToString:@"searchListing"])
	{
		TGSearchViewController *searchVC = segue.destinationViewController;
		searchVC.listingViewController = self;
	}
	else if ([segue.identifier isEqualToString:@"listingToSubredditInfo"])
	{
		TGSubredditInfoViewController *subredditInfoVC = segue.destinationViewController;
		subredditInfoVC.popoverPresentationController.sourceRect = self.navigationItem.titleView.frame;
		[subredditInfoVC loadInfoForSubreddit:self.pagination.subreddit];
	}

}

@end
