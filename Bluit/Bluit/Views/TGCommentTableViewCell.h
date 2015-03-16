//
//  TGCommentTableViewCell.h
//  redditPad
//
//  Created by Tom Graham on 13/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TGCommentTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextView *body;
@property (weak, nonatomic) IBOutlet UILabel *score;
@property (weak, nonatomic) IBOutlet UILabel *timestamp;
@property (weak, nonatomic) IBOutlet UILabel *author;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftMargin;
@property (assign, nonatomic) float originalLeftMargin;

@end
