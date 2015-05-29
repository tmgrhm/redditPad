//
//  TGMediaViewController.h
//  redditPad
//
//  Created by Tom Graham on 27/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TGMedia.h"

@interface TGMediaGalleryViewController : UIViewController

@property (strong, nonatomic) NSArray *media; // array of TGMedia objects

- (void) loadMedia;

@end
