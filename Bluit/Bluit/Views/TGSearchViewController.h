//
//  TGSearchViewController.h
//  redditPad
//
//  Created by Tom Graham on 12/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TGSearchViewController : UIViewController <UITextFieldDelegate>

- (BOOL)textFieldShouldReturn:(UITextField *)textField;

@end
