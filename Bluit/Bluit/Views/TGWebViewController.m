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
@property (weak, nonatomic) IBOutlet UIView *shadowView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButton;

@end

@implementation TGWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self createShadow];
	
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
	containerCALayer.borderColor = [[UIColor colorWithRed:0.776 green:0.788 blue:0.8 alpha:0.6] CGColor];
	containerCALayer.borderWidth = 0.5f;
	// TODO get a performant shadow
	//	containerCALayer.shouldRasterize = YES;
	//	containerCALayer.rasterizationScale = UIScreen.mainScreen.scale;
	containerCALayer.shadowColor = [[UIColor colorWithRed:0.776 green:0.788 blue:0.8 alpha:1] CGColor];
	containerCALayer.shadowOpacity = 0.5f;
	containerCALayer.shadowRadius = 6.0f;
	CGRect bounds = self.shadowView.bounds;
	bounds = CGRectMake(bounds.origin.x, bounds.origin.y + 1, bounds.size.width, bounds.size.height);
	containerCALayer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:containerCALayer.cornerRadius].CGPath;

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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (IBAction)closePressed:(id)sender {	// TODO
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
