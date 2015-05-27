//
//  TGMediaViewController.h
//  redditPad
//
//  Created by Tom Graham on 27/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TGMediaGalleryViewController : UIViewController

@property (strong, nonatomic) NSURL *mediaURL;

- (void)loadMediaFromURL:(NSURL *)url;

@end
