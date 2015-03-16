//
//  TGLinkViewController.h
//  redditPad
//
//  Created by Tom Graham on 13/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TGLink.h"

@interface TGLinkViewController : UIViewController

@property (strong, nonatomic) TGLink *link;
@property (strong, nonatomic) NSArray *comments;

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)url inRange:(NSRange)characterRange;

@end
