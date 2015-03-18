//
//  TGSelfpostViewCell.h
//  redditPad
//
//  Created by Tom Graham on 16/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TGSelfpostView : UIView

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *selfText;
@property (weak, nonatomic) IBOutlet UILabel *ptsCmtsSubLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeAuthorLabel;

@end
