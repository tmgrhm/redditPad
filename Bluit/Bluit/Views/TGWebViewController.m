//
//  TGWebViewController.m
//  redditPad
//
//  Created by Tom Graham on 11/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGWebViewController.h"

#import "ThemeManager.h"

@interface TGWebViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *fadeView;
@property (weak, nonatomic) IBOutlet UIView *shadowView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButton;

@end

@implementation TGWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[self.webView setDelegate:self];
	
	[self createShadow];
	[self themeAppearance];
	
	if (!self.url) self.url = self.link.url;
	[self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
	// TODO fix webView being wrong-size for sites like imgur and youtube
	
//	self.titleLabel.text = self.link.title; // TODO make dynamic per webview
	
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)createShadow
{
	CALayer *containerCALayer = self.shadowView.layer;
	containerCALayer.borderColor = [[ThemeManager separatorColor] CGColor];
	containerCALayer.borderWidth = 0.6f;
	// TODO get a performant shadow
	CGRect bounds = self.shadowView.bounds;
	bounds = CGRectMake(bounds.origin.x, bounds.origin.y + 2, bounds.size.width, bounds.size.height);
	containerCALayer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:containerCALayer.cornerRadius].CGPath;
	containerCALayer.shadowColor = [[ThemeManager shadowColor] CGColor];
	containerCALayer.shadowOpacity = 0.5f;
	containerCALayer.shadowRadius = 6.0f;
	
	self.fadeView.backgroundColor = [ThemeManager backgroundColor];
	self.fadeView.alpha = 0.7f;
}

- (void) themeAppearance
{
	// empty
}

- (IBAction)sharePressed:(id)sender
{ 	// TODO
	UIActivityViewController *shareSheet = [[UIActivityViewController alloc]
											initWithActivityItems:@[self.link.title, self.url] // TODO handle !self.link
											applicationActivities:nil];
	
	shareSheet.popoverPresentationController.sourceView = self.view;
	
	[self presentViewController:shareSheet
					   animated:YES
					 completion:nil];
	
	// TODO if launchservices invalidationhandler called — http://stackoverflow.com/questions/25192313/sharing-via-uiactivityviewcontroller-to-twitter-facebook-etc-causing-crash
}

# pragma mark - WebView Delegate
- (void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	NSLog(@"failed loading: %@ \n%@", webView.request.URL, error.description);
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (IBAction)closePressed:(id)sender
{	// TODO
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
