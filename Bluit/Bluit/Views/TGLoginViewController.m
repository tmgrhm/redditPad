//
//  TGLoginViewController.m
//  redditPad
//
//  Created by Tom Graham on 12/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGLoginViewController.h"

#import "TGRedditClient.h"
#import "ThemeManager.h"

@interface TGLoginViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UILabel *loginSuccessfulLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *themeSegControl;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation TGLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self themeAppearance];
	
	[self oAuthLoginPressed:self];
	
	NSString *theme = [ThemeManager sharedManager].theme[@"themeName"];
	self.themeSegControl.selectedSegmentIndex = [theme isEqualToString:@"lightTheme"] ? 0 : 1;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup & Appearance
- (void) themeAppearance
{
	self.view.backgroundColor = [ThemeManager backgroundColor];
}

#pragma mark - IBAction

- (IBAction)oAuthLoginPressed:(id)sender
{
	TGRedditClient *client = [TGRedditClient sharedClient];
	
//	[self performSegueWithIdentifier:@"loginWebView" sender:self];
	[self.webView setDelegate:self];
	[self.webView loadRequest:[NSURLRequest requestWithURL:[client oAuthLoginURL]]];
}

- (IBAction)themeSegControlValueChanged:(UISegmentedControl *)sender
{
	NSString *title = [sender titleForSegmentAtIndex:sender.selectedSegmentIndex];
	NSString *theme = [title isEqualToString:@"Light"] ? kTGThemeDefault : kTGThemeDark;
	NSLog(@"Changed theme: %@", theme);
	[[ThemeManager sharedManager] setCurrentTheme:theme];
	
//	NSArray *windows = [UIApplication sharedApplication].windows;
//	for (UIWindow *window in windows) {
//		for (UIView *view in window.subviews) {
//			[view removeFromSuperview];
//			[window addSubview:view];
//		}
//	}
}

#pragma mark -
- (void) loginSuccessful
{
	self.loginSuccessfulLabel.hidden = NO;
	self.usernameField.alpha = 0.5;
	self.passwordField.alpha = 0.5;
	self.loginButton.alpha = 0.5;
}

#pragma mark - WebView Delegate
- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if (navigationType == UIWebViewNavigationTypeFormSubmitted)
	{
		NSURL *url = request.URL;
		if ([[url scheme] isEqualToString:@"redditpad"])
		{
			[[TGRedditClient sharedClient] loginWithOAuthResponse:url];
//			[[UIApplication sharedApplication] openURL:url]; // TODO handle response via delegate instead?
			return NO; // don't let the webview process it
		}
	}
	
	return YES;
}

#pragma mark - Navigation

/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//     Get the new view controller using [segue destinationViewController].
//     Pass the selected object to the new view controller.
	
	if ([[segue identifier] isEqualToString:@"loginWebView"])
	{
		TGWebViewController *webVC = [segue destinationViewController];
		NSLog(@"%@", self.loginURL);
		[webVC setUrl:self.loginURL];
	}
}*/

@end
