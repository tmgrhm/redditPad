//
//  TGMedia.h
//  redditPad
//
//  Created by Tom Graham on 28/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, TGMediaType)
{
	TGMediaTypeUnknown,
	TGMediaTypeImage,
	TGMediaTypeGif,
	TGMediaTypeVideo
};

@interface TGMedia : NSObject

@property (nonatomic) TGMediaType type;
@property (strong, nonatomic) NSURL *url;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *caption;
@property (nonatomic) CGSize size;

@end
