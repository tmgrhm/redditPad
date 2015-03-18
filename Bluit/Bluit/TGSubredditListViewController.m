//
//  TGSubredditListViewController.m
//  redditPad
//
//  Created by Tom Graham on 03/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGSubredditListViewController.h"
#import "FrontPageViewController.h"
#import "TGRedditClient.h"

@interface TGSubredditListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSArray *subreddits;
@property (strong, nonatomic) NSString *selectedRow;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation TGSubredditListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
	
	__weak __typeof(self)weakSelf = self;
	[[TGRedditClient sharedClient] retrieveUserSubscriptionsWithCompletion:^(NSArray *subreddits){
		weakSelf.subreddits = subreddits;
		[weakSelf reloadTableViewData];
	}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITableView
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
	return self.subreddits.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"TGSubredditTableViewCell" forIndexPath:indexPath];
	cell.textLabel.text = self.subreddits[indexPath.row][@"data"][@"url"];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// When user selects a row
   [tableView deselectRowAtIndexPath:indexPath animated:TRUE];
	
//	self.selectedSubreddit = self.subreddits[indexPath.row];
	// Perform segue
	
	self.selectedRow = self.subreddits[indexPath.row][@"data"][@"url"];
	NSLog(@"Selected %@", self.subreddits[indexPath.row][@"data"][@"url"]);
	[self performSegueWithIdentifier:@"subredditListToListing" sender:self];
	
//	[self performSegueWithIdentifier:@"listingToWebView" sender:self];
//	[tableView selectRowAtIndexPath:nil
//						   animated:NO
//					 scrollPosition:UITableViewScrollPositionNone];	// TODO better way?
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.
	
	if ([segue.identifier isEqualToString:@"subredditListToListing"])
	{
		NSLog(@"SubredditListVC requesting fpVC for: %@", self.selectedRow);
		FrontPageViewController *fpVC = segue.destinationViewController;
		fpVC.subreddit = self.selectedRow;
//		webVC.link = self.selectedLink;
	}
}

@end
