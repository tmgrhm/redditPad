//
//  TGSelfPostHeaderViewController.m
//  redditPad
//
//  Created by Tom Graham on 14/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGSelfPostHeaderViewController.h"

@interface TGSelfPostHeaderViewController ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *selfPostLabel;
@property (weak, nonatomic) IBOutlet UILabel *ptsCmtsSubLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeAuthorLabel;

@end

@implementation TGSelfPostHeaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	NSLog(@"loading selfpostheaderview: %@",self.link.title);
	
	self.titleLabel.text = self.link.title;
	self.selfPostLabel.text = self.link.selfText;
	self.ptsCmtsSubLabel.text = [NSString stringWithFormat:@"%lu points, %lu comments in /r/%@", self.link.score, self.link.totalComments, self.link.subreddit];
	self.timeAuthorLabel.text = [NSString stringWithFormat:@"timestamp, by %@", self.link.author]; // TODO timestamp
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
