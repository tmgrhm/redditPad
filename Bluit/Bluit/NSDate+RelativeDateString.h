//
//  NSDate+RelativeDateString.h
//  redditPad
//
//  Created by Tom Graham on 06/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const kRelativeDateStringSuffixYear		= @"yr";
static NSString * const kRelativeDateStringSuffixMonth		= @"mth";
static NSString * const kRelativeDateStringSuffixWeek		= @"wk";
static NSString * const kRelativeDateStringSuffixDay		= @"day";
static NSString * const kRelativeDateStringSuffixHour		= @"hr";
static NSString * const kRelativeDateStringSuffixMinute		= @"min";
static NSString * const kRelativeDateStringSuffixSecond		= @"sec";
static NSString * const kRelativeDateStringSuffixJustNow	= @"just now";

@interface NSDate (RelativeDateString)

+ (NSString *) relativeDateStringForDate:(NSDate *)date;
- (NSString *) relativeDateString;

@end
