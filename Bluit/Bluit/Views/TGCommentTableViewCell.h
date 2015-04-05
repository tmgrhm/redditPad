//
//  TGCommentTableViewCell.h
//  redditPad
//
//  Created by Tom Graham on 13/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TGCommentTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextView *bodyLabel;
@property (weak, nonatomic) IBOutlet UILabel *pointsLabel;
@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;

@property (nonatomic, getter=isCollapsed) BOOL collapsed;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftMargin;
@property (assign, nonatomic) float originalLeftMargin;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topMargin;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *midMargin;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *metaHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *btmMargin;

- (CGFloat) calculateHeightForConfiguredCell;

@end
