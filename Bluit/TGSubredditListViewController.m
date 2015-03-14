//
//  TGSubredditListViewController.m
//  redditPad
//
//  Created by Tom Graham on 03/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGSubredditListViewController.h"
#import "TGRedditClient.h"

@interface TGSubredditListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSArray *subreddits;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation TGSubredditListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
	
	__weak __typeof(self)weakSelf = self;
	[[TGRedditClient sharedClient] retrieveUserSubscriptionsWithCompletion:^(NSArray *subreddits){
		weakSelf.subreddits = subreddits;
		[weakSelf.tableView reloadData];
	}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITableView
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
//	self.selectedLink = self.subreddits[indexPath.row];
	// Perform segue
	
	NSLog(@"Selected %@", self.subreddits[indexPath.row][@"data"][@"url"]);
	
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
	
	if ([segue.identifier isEqualToString:@"listingToWebView"])
	{
//		TGWebViewController *webVC = segue.destinationViewController;
//		webVC.link = self.selectedLink;
	}
}

@end
