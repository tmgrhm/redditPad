//
//  TGLoginViewController.m
//  redditPad
//
//  Created by Tom Graham on 12/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGLoginViewController.h"
#import "TGRedditClient.h"

@interface TGLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UILabel *loginSuccessfulLabel;

@end

@implementation TGLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginPressed:(id)sender
{
	TGRedditClient *client = [TGRedditClient sharedClient];
	
	__weak __typeof(self)weakSelf = self;
	[client loginWithUsername:self.usernameField.text
					 password:self.passwordField.text
			   withCompletion:^void(void) {
		[weakSelf loginSuccessful];
	}];
}

- (void) loginSuccessful
{
	self.loginSuccessfulLabel.hidden = NO;
	self.usernameField.alpha = 0.5;
	self.passwordField.alpha = 0.5;
	self.loginButton.alpha = 0.5;
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
