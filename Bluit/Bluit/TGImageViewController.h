//
//  TGImageViewController.h
//  redditPad
//
//  Created by Tom Graham on 27/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TGImageViewController : UIViewController

@property (strong, nonatomic) NSURL *imageURL;

- (instancetype) initWithImage:(UIImage *)image;
- (void)setImage:(UIImage *)image;
- (void)loadImageFromURL:(NSURL *)url;

@end
