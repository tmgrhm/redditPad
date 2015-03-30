//
//  FrontPageViewController.m
//  redditPad
//
//  Created by Tom Graham on 03/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "FrontPageViewController.h"
#import "TGLink.h"
#import "TGRedditClient.h"
#import "TGListingTableViewCell.h"
#import "TGWebViewController.h"
#import "TGLinkViewController.h"
#import "TGPostViewController.h"
#import "TGImageViewController.h"

#import "ThemeManager.h"

#import <AFNetworking/UIImageView+AFNetworking.h>

@interface FrontPageViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *listings;
@property (strong, nonatomic) TGLink *selectedLink;

@end

@implementation FrontPageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
	
	self.tableView.estimatedRowHeight = 80.0;
	self.tableView.rowHeight = UITableViewAutomaticDimension;
	
	[self loadSubreddit:self.subreddit];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self reloadTableViewData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup & Appearance
- (void) themeAppearance
{
	// empty
}

#pragma mark - IBAction

- (IBAction)refreshButtonPressed:(id)sender
{
	[self loadFrontPage];
}

#pragma mark - Loading Data

- (void)loadFrontPage
{
	[self loadSubreddit:@"hot"];
}

- (void)loadSubreddit:(NSString *)subredditURL
{
	NSLog(@"fpVC.subreddit: %@", self.subreddit);
	
	self.title = subredditURL;
	
	if ([subredditURL length] == 0)	subredditURL = @"hot";
	if ([subredditURL isEqualToString:@"hot"])	self.title = @"Front Page";
	
	[[TGRedditClient sharedClient] requestSubreddit:subredditURL withCompletion:^(NSArray *collection, NSError *error) {
		self.listings = collection;
		[self reloadTableViewData];
	}];
}


#pragma mark - TableView
- (void) reloadTableViewData
{
	[self.tableView beginUpdates];
	[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
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
	TGListingTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"TGListingTableViewCell" forIndexPath:indexPath];
	
	TGLink *link = ((TGLink *)self.listings[indexPath.row]);
	
	cell.title.text = link.title;
	cell.score.text = [NSString stringWithFormat:@"%lu", (unsigned long)link.score];
	cell.subreddit.text = link.subreddit;
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
	
	cell.score.textColor = [ThemeManager secondaryTextColor];
	cell.timestamp.textColor = [ThemeManager secondaryTextColor];
	cell.author.textColor = [ThemeManager secondaryTextColor];
	cell.domain.textColor = [ThemeManager secondaryTextColor];
	cell.totalComments.textColor = [ThemeManager tintColor];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// When user selects a row
   [tableView deselectRowAtIndexPath:indexPath animated:TRUE];
	
	self.selectedLink = self.listings[indexPath.row];
	// Perform segue
	
	NSString *lastPathComponent = self.selectedLink.url.pathComponents.lastObject;
	
	if ([lastPathComponent hasSuffix:@".png"] || [lastPathComponent hasSuffix:@".jpg"] || [lastPathComponent hasSuffix:@".jpeg"] || [lastPathComponent hasSuffix:@".gif"])
	{
		[self performSegueWithIdentifier:@"listingToImageView" sender:self];
	}
	else
	{
		[self performSegueWithIdentifier:@"listingToWebView" sender:self];
	}
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.
	
	if ([segue.identifier isEqualToString:@"listingToWebView"])
	{
		TGWebViewController *webVC = segue.destinationViewController;
		webVC.link = self.selectedLink;
	}
	else if ([segue.identifier isEqualToString:@"listingToImageView"])
	{
		TGImageViewController *imageVC = segue.destinationViewController;
		imageVC.imageURL = self.selectedLink.url;
	}
	else if ([segue.identifier isEqualToString:@"listingToLinkView"])
	{
		TGLinkViewController *linkVC = segue.destinationViewController;
		
		NSInteger indexPathRow = 0;
		if ([sender isKindOfClass:[UIButton class]])
		{
			UIButton *commentsButton = (UIButton *)sender;
			indexPathRow = commentsButton.tag;
			// TODO change how the row is identified
			// http://stackoverflow.com/questions/23784630/
		}
		linkVC.link = self.listings[indexPathRow];
	}
	else if ([segue.identifier isEqualToString:@"listingToPostView"])
	{
		TGPostViewController *linkVC = segue.destinationViewController;
		
		NSInteger indexPathRow = 0;
		if ([sender isKindOfClass:[UIButton class]])
		{
			UIButton *commentsButton = (UIButton *)sender;
			indexPathRow = commentsButton.tag;
			// TODO change how the row is identified
			// http://stackoverflow.com/questions/23784630/
		}
		linkVC.link = self.listings[indexPathRow];
	}

}

@end
