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
	
	NSLog(@"fpVC.subreddit: %@", self.subreddit);
	
	[self loadSubreddit:self.subreddit];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadFrontPage
{
	[self loadSubreddit:@"hot"];
}

- (void)loadSubreddit:(NSString *)subredditURL
{
	self.title = subredditURL;
	
	if ([subredditURL length] == 0)
	{
		subredditURL = @"hot";
		self.title = @"Front Page";
	}
	
	[[TGRedditClient sharedClient] requestSubreddit:subredditURL withCompletion:^(NSArray *collection, NSError *error) {
		self.listings = collection;
		[self.tableView reloadData];
	}];
}

- (IBAction)refreshButtonPressed:(id)sender
{
	[self loadFrontPage];
}

#pragma mark - UITableView
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
	cell.domain.text = link.domain;
	cell.author.text = link.author;
	cell.totalComments.text = [NSString stringWithFormat:@"%lu", (unsigned long)link.totalComments];
	
	cell.commentsButton.tag = indexPath.row;
	if (link.isSelfpost)
	{
		cell.domain.hidden = YES;
		[cell.thumbnail setImage:nil];
	} else {
		cell.domain.text = link.domain;
		[cell.thumbnail setImageWithURL:link.thumbnailURL];
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// When user selects a row
	self.selectedLink = self.listings[indexPath.row];
	// Perform segue
	[self performSegueWithIdentifier:@"listingToWebView" sender:self];
	[tableView selectRowAtIndexPath:nil
						   animated:NO
					 scrollPosition:UITableViewScrollPositionNone];	// TODO better way?
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
}

@end
