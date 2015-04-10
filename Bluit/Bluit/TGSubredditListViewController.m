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
#import "ThemeManager.h"

NSString * const kFrontPageDisplayName = @"Front Page";
NSString * const kAllSubredditsDisplayName = @"All";
NSString * const kRandomSubreddit = @"Random Subreddit";
NSString * const kDiscoverSubreddits = @"Discover Subreddits";
NSString * const kFrontPageURL = @"hot";
NSString * const kAllSubredditsURL = @"/r/all";
NSString * const kRandomSubredditURL = @"/r/random";


@interface TGSubredditListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSArray *navigationOptions;
@property (strong, nonatomic) NSArray *subreddits;
@property (strong, nonatomic) NSString *selectedSubreddit;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation TGSubredditListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
	[self themeAppearance];
	
	self.navigationOptions = @[kFrontPageDisplayName,
							   kAllSubredditsDisplayName,
							   kRandomSubreddit,
							   kDiscoverSubreddits];
	
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

#pragma mark - Setup & Appearance
- (void) themeAppearance
{
	self.view.backgroundColor = [ThemeManager backgroundColor];
}


#pragma mark - UITableView
- (void) reloadTableViewData
{
	[self.tableView beginUpdates];
	NSRange range = NSMakeRange(0, [self numberOfSectionsInTableView:self.tableView]); // all sections
	NSIndexSet *sections = [NSIndexSet indexSetWithIndexesInRange:range];
	[self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
	[self.tableView endUpdates];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section)
	{
		case 0:		return self.navigationOptions.count;
		case 1:		return self.subreddits.count;
		default:	return 0;
	}
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"TGSubredditTableViewCell" forIndexPath:indexPath];
	
	switch(indexPath.section)
	{
		case 0:
			cell.textLabel.text = self.navigationOptions[indexPath.row];
			break;
		case 1:
			cell.textLabel.text = self.subreddits[indexPath.row][@"data"][@"url"];
			break;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// When user selects a row
	[tableView deselectRowAtIndexPath:indexPath animated:TRUE];
	
	switch(indexPath.section)
	{
		case 0:
		{
			NSString *selectedString = self.navigationOptions[indexPath.row];
			if ([selectedString isEqualToString:kFrontPageDisplayName])
				self.selectedSubreddit = kFrontPageURL;			// TODO make @"" and pass the sort method with the requestURL
			else if ([selectedString isEqualToString:kAllSubredditsDisplayName])
				self.selectedSubreddit = kAllSubredditsURL;
			else if ([selectedString isEqualToString:kRandomSubreddit])
				self.selectedSubreddit = kRandomSubredditURL;	// TODO set the listing navbar title correctly
			break;
		}
		case 1:
			self.selectedSubreddit = self.subreddits[indexPath.row][@"data"][@"url"];
			break;
	}
	
	[self.delegate didSelectSubreddit:self.selectedSubreddit];
	
	NSLog(@"Selected %@", self.selectedSubreddit);
//	[self performSegueWithIdentifier:@"subredditListToListing" sender:self];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.
	
	if ([segue.identifier isEqualToString:@"subredditListToListing"])
	{
		NSLog(@"SubredditListVC requesting fpVC for: %@", self.selectedSubreddit);
		FrontPageViewController *fpVC = segue.destinationViewController;
		fpVC.subreddit = self.selectedSubreddit;
//		webVC.link = self.selectedLink;
	}
}

@end
