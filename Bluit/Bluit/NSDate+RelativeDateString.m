//
//  NSDate+RelativeDateString.m
//  redditPad
//
//  Created by Tom Graham on 06/04/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "NSDate+RelativeDateString.h"

@implementation NSDate (RelativeDateString)

+ (NSString *) relativeDateStringForDate:(NSDate *)date
{
	NSCalendarUnit units = NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay | NSCalendarUnitWeekOfYear | NSCalendarUnitMonth	| NSCalendarUnitYear;
	NSDateComponents *components = [[NSCalendar currentCalendar] components:units
																   fromDate:date
																	 toDate:[NSDate date]
																	options:0];
	
	// if `date` is before "now" (i.e. in the past) then the components will be positive
	NSString *component;
	long value;
	
	if (components.year > 0) {
		component = @"yr";
		value = components.year;
	} else if (components.month > 0) {
		component = @"mth";
		value = components.month;
	} else if (components.weekOfYear > 0) {
		component = @"wk";
		value = components.weekOfYear;
	} else if (components.day > 0) {
		component = @"day";
		value = components.day;
	} else if (components.hour > 0) {
		component = @"hr";
		value = components.hour;
	} else if (components.minute > 0) {
		component = @"min";
		value = components.minute;
	} else {
		return @"just now";
	}
	
	NSString *plural = value == 1 ? @"" : @"s";
	return [NSString stringWithFormat:@"%ld %@%@", value, component, plural];
}

- (NSString *) relativeDateString
{
	return [NSDate relativeDateStringForDate:self];
}

@end
