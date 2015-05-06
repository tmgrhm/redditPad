//
//  TGSubredditInfoCell.h
//  redditPad
//
//  Created by Tom Graham on 23/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TGSubredditInfoCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *subscribersLabel;
@property (weak, nonatomic) IBOutlet UILabel *hereNowLabel;
@property (weak, nonatomic) IBOutlet UIButton *subscribeButton;

- (void) setNumSubscribers:(unsigned long)subscribers;
- (void) setNumActiveUsers:(unsigned long)activeUsers;
- (void) setSubscribeButtonTitle:(NSString *)title;

@end
