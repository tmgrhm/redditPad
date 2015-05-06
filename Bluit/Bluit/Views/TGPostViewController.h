//
//  TGPostViewController.h
//  redditPad
//
//  Created by Tom Graham on 23/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TGLink.h"

@interface TGPostViewController : UIViewController <UIViewControllerTransitioningDelegate>

@property (strong, nonatomic) TGLink *link;

@end
