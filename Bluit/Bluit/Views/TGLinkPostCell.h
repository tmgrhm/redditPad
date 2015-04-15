//
//  TGLinkPostCell.h
//  redditPad
//
//  Created by Tom Graham on 25/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TGLinkPostCell : UITableViewCell

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topMargin;

@property (weak, nonatomic) IBOutlet UITextView *title;
@property (weak, nonatomic) IBOutlet UITextView *content;
@property (weak, nonatomic) IBOutlet UILabel *metadata;
@property (weak, nonatomic) IBOutlet UILabel *numComments;

@property (weak, nonatomic) IBOutlet UIButton *upvoteButton;
@property (weak, nonatomic) IBOutlet UIButton *downvoteButton;
@property (weak, nonatomic) IBOutlet UIView *mainBackground;

@property (weak, nonatomic) IBOutlet UIView *separator;

@end
