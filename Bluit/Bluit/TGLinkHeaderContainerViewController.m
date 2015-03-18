//
//  TGLinkHeaderContainerViewController.m
//  redditPad
//
//  Created by Tom Graham on 14/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGLinkHeaderContainerViewController.h"
#import "TGSelfPostHeaderViewController.h"
#import "TGLinkHeaderViewController.h"

@interface TGLinkHeaderContainerViewController ()

@end

@implementation TGLinkHeaderContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
//	NSLog(@"Container VC loaded, %@", self.link.selfText);
	
	NSString *segueIdentifier = self.link.isSelfpost ? @"embedSelfpostHeaderView" : @"embedLinkHeaderView";
	[self performSegueWithIdentifier:segueIdentifier sender:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//	NSLog(@"TGLinkHeaderCOntainerVC prepareForSegue:%@", segue.identifier);
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
	
	UIViewController *headerVC = segue.destinationViewController;
	
	if ([segue.identifier isEqualToString:@"embedLinkHeaderView"])
	{
		[(TGLinkHeaderViewController *) headerVC setLink:self.link];
	} else {
		[(TGSelfPostHeaderViewController *) headerVC setLink:self.link];
	}
	[self addChildViewController:headerVC];
//	headerVC.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	[self.view addSubview:headerVC.view];
	[headerVC didMoveToParentViewController:self];
	
//	NSLog(@"performed %@", segue.identifier);
}

@end
