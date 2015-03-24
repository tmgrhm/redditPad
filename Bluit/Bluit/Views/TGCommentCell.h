//
//  TGCommentCell.h
//  redditPad
//
//  Created by Tom Graham on 23/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TGCommentCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *bodyLabel;			// TODO UITextView
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UILabel *pointsLabel;
@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;

@property (nonatomic, getter=isCollapsed) BOOL collapsed;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftMargin;
@property (nonatomic) float originalLeftMargin;

@end
