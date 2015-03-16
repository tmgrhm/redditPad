//
//  TGWebViewController.m
//  redditPad
//
//  Created by Tom Graham on 11/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGWebViewController.h"

@interface TGWebViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *fadeView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButton;

@end

@implementation TGWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	if (!self.url) self.url = self.link.url;
	
	[self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
	// TODO fix webView being wrong-size for sites like imgur and youtube
	
//	self.titleLabel.text = self.link.title; // TODO make dynamic per webview
	
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (IBAction)closePressed:(id)sender {	// TODO
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sharePressed:(id)sender { 	// TODO
	
	UIActivityViewController *shareSheet = [[UIActivityViewController alloc]
											initWithActivityItems:@[self.link.title, self.url] // TODO handle !self.link
											applicationActivities:nil];
	
	shareSheet.popoverPresentationController.sourceView = self.view;
	
	[self presentViewController:shareSheet
					   animated:YES
					 completion:nil];
}

@end
