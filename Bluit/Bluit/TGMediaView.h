//
//  TGMediaView.h
//  redditPad
//
//  Created by Tom Graham on 27/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TGMediaView : UIView

@property (strong, nonatomic) NSURL *mediaURL;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *caption;

- (void)loadMediaFromURL:(NSURL *)url;

@end
