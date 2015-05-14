//
//  TGSubredditInfoViewController.m
//  redditPad
//
//  Created by Tom Graham on 23/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGSubredditInfoViewController.h"

#import "TGSubredditInfoCell.h"
#import "TGSubredditSidebarCell.h"

#import "ThemeManager.h"

#import "TGRedditClient.h"

@interface TGSubredditInfoViewController ()

@property (strong, nonatomic) TGSubredditInfoCell *cachedInfoCell;
@property (strong, nonatomic) TGSubredditSidebarCell *cachedSidebarCell;
@property (nonatomic) CGFloat infoCellHeight;
@property (nonatomic) CGFloat sidebarCellHeight;

@property (strong, nonatomic) NSArray *actionButtons;

@end

@implementation TGSubredditInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.preferredContentSize = CGSizeMake(450, 450);

	self.actionButtons = @[@"Add to a Multireddit",
						   @"Message the Mods",
						   @"View the Wiki",
						   @"Open in Safari"];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) loadInfoForSubreddit:(NSString *)subredditTitle
{
	[[TGRedditClient sharedClient] getSubredditInfoFor:subredditTitle withCompletion:^(TGSubreddit *subreddit) {
		self.subreddit = subreddit;
		[self reloadTableViewData];
		self.preferredContentSize = CGSizeMake(450, self.tableView.contentSize.height);
	}];
}

- (void) updateSubscribeButton
{
	NSString *subscribeBtnTitle = self.subreddit.userIsSubscriber ? @"UNSUBSCRIBE" : @"SUBSCRIBE";
	[self.cachedInfoCell setSubscribeButtonTitle:subscribeBtnTitle];
}

#pragma mark - IBAction

- (void) subscribeButtonPressed:(id)sender
{
	[[TGRedditClient sharedClient] subscribe:self.subreddit];
	self.subreddit.userIsSubscriber = !self.subreddit.userIsSubscriber;
	[self updateSubscribeButton];
}

#pragma mark - TableView

- (void) reloadTableViewData
{
	[self.tableView reloadData];
	[self.tableView beginUpdates];
	[self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfSections)]
				  withRowAnimation:UITableViewRowAnimationAutomatic];
	[self.tableView endUpdates];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (self.subreddit == nil)	return 0;
	else							return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section) {
		case 0: return 1; // infoCell
		case 1: return self.actionButtons.count;
		case 2: return 1; // sidebarCell
		default: return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch(indexPath.section) {
		case 0:
			return self.infoCell;
		case 1:
			return [self actionCellAtIndexPath:indexPath];
		case 2:
			return self.sidebarCell;
		default:
			return nil;
	}
}

- (TGSubredditInfoCell *) infoCell
{
    if (self.cachedInfoCell) return self.cachedInfoCell;
    
	TGSubredditInfoCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"TGSubredditInfoCell"];
	[self configureInfoCell:cell];
	
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	
	self.cachedInfoCell = cell;
	
	return self.cachedInfoCell;
}

- (void) configureInfoCell:(TGSubredditInfoCell *)cell
{
	// TODO
	
	cell.nameLabel.text = [self.subreddit.url absoluteString];
	NSMutableAttributedString *attrName = [cell.nameLabel.attributedText mutableCopy];
	// style leading `/r/`
	NSDictionary *attributes = @{NSForegroundColorAttributeName:[ThemeManager colorForKey:kTGThemeSecondaryTextColor],
								 NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Medium" size:17.0f]};
	[attrName addAttributes:attributes range:NSMakeRange(0, 3)];
	// trim trailing `/`
	attrName = [[attrName attributedSubstringFromRange:NSMakeRange(0, attrName.length-1)] mutableCopy];
	cell.nameLabel.attributedText = attrName;
	
	cell.descriptionLabel.text = self.subreddit.publicDescription;
	[cell setNumSubscribers:self.subreddit.subscribers];
	[cell setNumActiveUsers:self.subreddit.activeUsers];

	[cell.subscribeButton addTarget:self action:@selector(subscribeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	NSString *subscribeBtnTitle = self.subreddit.userIsSubscriber ? @"UNSUBSCRIBE" : @"SUBSCRIBE";
	[cell setSubscribeButtonTitle:subscribeBtnTitle];
}

- (UITableViewCell *)actionCellAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"BasicTableViewCell" forIndexPath:indexPath];
	[self configureActionCell:cell atIndexPath:indexPath];
	
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	
	return cell;
}

- (void)configureActionCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	NSString *action = self.actionButtons[indexPath.row];
	cell.textLabel.text = action;
	
	if (indexPath.row == 0)	{
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; // TODO custom
		cell.textLabel.textColor = [ThemeManager colorForKey:kTGThemeTextColor];
	}
	else cell.textLabel.textColor = [ThemeManager colorForKey:kTGThemeTintColor];
}

- (TGSubredditSidebarCell *) sidebarCell
{
    if (self.cachedSidebarCell) return self.cachedSidebarCell;
    
	TGSubredditSidebarCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"TGSubredditSidebarCell"];
	[self configureSidebarCell:cell];
	
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	
	self.cachedSidebarCell = cell;
	
	return self.cachedSidebarCell;
}

- (void) configureSidebarCell:(TGSubredditSidebarCell *)cell
{
	// TODO
	cell.sidebarContent.text = self.subreddit.sidebar;
	
	cell.sidebarContent.textColor = [ThemeManager colorForKey:kTGThemeTextColor];
	cell.sidebarHeaderBG.backgroundColor = [ThemeManager colorForKey:kTGThemeBackgroundColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch(indexPath.section) {
		case 0: return [self heightForInfoCell];
		case 1: return 50;
		case 2: return [self heightForSidebarCell];
		default: return 0;
	}
}

- (CGFloat)heightForInfoCell
{
	if (self.infoCellHeight != 0) return self.infoCellHeight;
	
	static TGSubredditInfoCell *sizingCell = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sizingCell = [self.tableView dequeueReusableCellWithIdentifier:@"TGSubredditInfoCell"];
	});
	
	[self configureInfoCell:sizingCell];
	
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
	
	self.infoCellHeight = size.height + 1.0f; // Add 1.0f for the cell separator height
	return self.infoCellHeight;
}

- (CGFloat) heightForSidebarCell
{
	if (self.sidebarCellHeight != 0) return self.sidebarCellHeight;
	
	static TGSubredditSidebarCell *sizingCell = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sizingCell = [self.tableView dequeueReusableCellWithIdentifier:@"TGSubredditSidebarCell"];
	});
	
	[self configureSidebarCell:sizingCell];
	
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
	
	self.sidebarCellHeight = size.height + 1.0f; // Add 1.0f for the cell separator height
	return self.sidebarCellHeight;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch(indexPath.section) {
		case 0: // info tapped
			[tableView deselectRowAtIndexPath:indexPath animated:NO];
			break;
		case 1: // action tapped
			switch (indexPath.row) { // TODO
				case 3:
				{
					NSString *safariUrlString = [NSString stringWithFormat:@"https://www.reddit.com/%@", self.subreddit.url];
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:safariUrlString]];
					break;
				}
				default:
					break;
			}
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
			break;
		case 2: // sidebar tapped
			[tableView deselectRowAtIndexPath:indexPath animated:NO];
			break;
	 }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
