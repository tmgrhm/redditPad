//
//  TGLinkPostCell.h
//  redditPad
//
//  Created by Tom Graham on 25/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TGLinkPostCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *title;
@property (weak, nonatomic) IBOutlet UILabel *ptsCmtsSub;
@property (weak, nonatomic) IBOutlet UILabel *timeAuthor;

@end
