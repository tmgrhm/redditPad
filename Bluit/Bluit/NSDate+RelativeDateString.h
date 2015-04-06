//
//  NSDate+RelativeDateString.h
//  redditPad
//
//  Created by Tom Graham on 06/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (RelativeDateString)

+ (NSString *) relativeDateStringForDate:(NSDate *)date;
- (NSString *) relativeDateString;

@end
