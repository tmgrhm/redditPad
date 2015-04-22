//
//  TGSearchViewController.m
//  redditPad
//
//  Created by Tom Graham on 12/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGSearchViewController.h"
#import "FrontPageViewController.h"

@interface TGSearchViewController ()
@property (weak, nonatomic) IBOutlet UITextField *searchTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *searchOptionSegControl;

@end

@implementation TGSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self.searchTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions


#pragma mark - TextField

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[self goToSubreddit];
	return NO;
}

#pragma mark - Searching

- (void) goToSubreddit
{
	NSString *subreddit = [NSString stringWithFormat:@"/r/%@/", self.searchTextField.text];
	[self.listingViewController loadSubreddit:subreddit];
	
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"goToSubreddit"])
	{
		// TODO remove? not using
		NSLog(@"goToSubreddit segue");
//		FrontPageViewController *listingVC = (FrontPageViewController *) segue.destinationViewController;
//		listingVC.pagination.subreddit = [NSString stringWithFormat:@"/r/%@/", self.searchTextField.text];
	}
}

@end
