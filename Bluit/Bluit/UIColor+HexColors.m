//
//  UIColor+HexColors.m
//  redditPad
//
//  Created by Tom Graham on 26/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "UIColor+HexColors.h"

@implementation UIColor (HexColors)

+(UIColor *)colorWithHexString:(NSString *)hexString {
	
	if ([hexString length] != 6) {
		return nil;
	}
	
	// Brutal and not-very elegant test for non hex-numeric characters
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^a-fA-F|0-9]" options:0 error:NULL];
	NSUInteger match = [regex numberOfMatchesInString:hexString options:NSMatchingReportCompletion range:NSMakeRange(0, [hexString length])];
	
	if (match != 0) {
		return nil;
	}
	
	NSRange rRange = NSMakeRange(0, 2);
	NSString *rComponent = [hexString substringWithRange:rRange];
	unsigned int rVal = 0;
	NSScanner *rScanner = [NSScanner scannerWithString:rComponent];
	[rScanner scanHexInt:&rVal];
	float rRetVal = (float)rVal / 254;
	
	
	NSRange gRange = NSMakeRange(2, 2);
	NSString *gComponent = [hexString substringWithRange:gRange];
	unsigned int gVal = 0;
	NSScanner *gScanner = [NSScanner scannerWithString:gComponent];
	[gScanner scanHexInt:&gVal];
	float gRetVal = (float)gVal / 254;
	
	NSRange bRange = NSMakeRange(4, 2);
	NSString *bComponent = [hexString substringWithRange:bRange];
	unsigned int bVal = 0;
	NSScanner *bScanner = [NSScanner scannerWithString:bComponent];
	[bScanner scanHexInt:&bVal];
	float bRetVal = (float)bVal / 254;
	
	return [UIColor colorWithRed:rRetVal green:gRetVal blue:bRetVal alpha:1.0f];
	
}

+(NSString *)hexValuesFromUIColor:(UIColor *)color {
	
	if (!color) {
		return nil;
	}
	
	if (color == [UIColor whiteColor]) {
		// Special case, as white doesn't fall into the RGB color space
		return @"ffffff";
	}
 
	CGFloat red;
	CGFloat blue;
	CGFloat green;
	CGFloat alpha;
	
	[color getRed:&red green:&green blue:&blue alpha:&alpha];
	
	int redDec = (int)(red * 255);
	int greenDec = (int)(green * 255);
	int blueDec = (int)(blue * 255);
	
	NSString *returnString = [NSString stringWithFormat:@"%02x%02x%02x", (unsigned int)redDec, (unsigned int)greenDec, (unsigned int)blueDec];
	
	return returnString;
	
}

@end