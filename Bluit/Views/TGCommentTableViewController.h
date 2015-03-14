//
//  TGCommentTableViewController.h
//  redditPad
//
//  Created by Tom Graham on 13/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TGLink;

@interface TGCommentTableViewController : UITableViewController

@property (strong, nonatomic) TGLink *link;
@property (strong, nonatomic) NSArray *comments;

@end
