//
//  TGWebViewController.m
//  redditPad
//
//  Created by Tom Graham on 11/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGWebViewController.h"
#import "TGPostViewController.h"

#import "ThemeManager.h"

#import <TUSafariActivity/TUSafariActivity.h>

@interface TGWebViewController () <UIWebViewDelegate, UIGestureRecognizerDelegate, UINavigationBarDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButton;

@end

@implementation TGWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self configureContentInsets];
	[self themeAppearance];
	[self configureGestureRecognizer];

	
	if (!self.url) self.url = self.link.url;
	[self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
	// TODO fix webView being wrong-size for sites like imgur and youtube
	
//	self.titleLabel.text = self.link.title; // TODO make dynamic per webview
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup & Customisation

- (void) configureContentInsets
{
	// TODO fix contentInsets-sized black bar at bottom before pageload
	float navBarHeight = CGRectGetHeight(self.navigationBar.frame);
	CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
	CGFloat statusBarHeight = MIN(statusBarSize.width, statusBarSize.height);
	
	float toolbarHeight = CGRectGetHeight(self.toolbar.frame);
	
	self.webView.scrollView.contentInset = UIEdgeInsetsMake(navBarHeight + statusBarHeight, 0, toolbarHeight, 0);
	self.webView.scrollView.scrollIndicatorInsets = self.webView.scrollView.contentInset;
}

- (void) themeAppearance
{
	// empty
}

- (void) configureGestureRecognizer
{
	UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self  action:@selector(swipeDown:)];
	swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
	swipeDown.numberOfTouchesRequired = 2;
	swipeDown.delegate = self;
	[self.webView addGestureRecognizer:swipeDown];
}

#pragma mark - IBActions

- (IBAction)closePressed:(id)sender
{	// TODO
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)commentsPressed:(id)sender
{
	if (self.link) // TODO handle by removing comments button
	{
		[self performSegueWithIdentifier:@"webViewToPostView" sender:self];
	}
}

- (IBAction)sharePressed:(id)sender
{ 	// TODO
	UIActivityViewController *shareSheet = [[UIActivityViewController alloc]
											initWithActivityItems:@[self.link.title, self.url] // TODO handle !self.link
											applicationActivities:@[safariActivity]];
	
	shareSheet.popoverPresentationController.sourceView = self.view;
	
	[self presentViewController:shareSheet
					   animated:YES
					 completion:nil];
	
	// TODO if launchservices invalidationhandler called — http://stackoverflow.com/questions/25192313/sharing-via-uiactivityviewcontroller-to-twitter-facebook-etc-causing-crash
}

- (void) swipeDown:(id)sender
{
//	NSLog(@"Swipe down");
	[self closePressed:sender];
}

#pragma mark - WebView Delegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	self.navigationBar.topItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

- (void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	NSLog(@"failed loading: %@ \n%@", webView.request.URL, error.description);
}

#pragma mark - GestureRecognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{	// allow swipeDown gesture to be recognised over webView
//	NSLog(@"Gesture:%@ \n\tOther: %@", gestureRecognizer, otherGestureRecognizer);
	return YES;
}

#pragma mark - NavigationBar Delegate

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar
{
	return UIBarPositionTopAttached;		// attach the navbar to the top of the window
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	
	if ([segue.identifier isEqualToString:@"webViewToPostView"])
	{
		TGPostViewController *postVC = [segue destinationViewController];
		postVC.transitioningDelegate = postVC;
		postVC.modalPresentationStyle = UIModalPresentationCustom;
		postVC.link = self.link;
	}
}



@end
