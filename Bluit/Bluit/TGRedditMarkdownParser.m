//
//  TGRedditMarkdownParser.m
//  redditPad
//
//  Created by Tom Graham on 14/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGRedditMarkdownParser.h"
#import "TGRedditClient.h"
#import "ThemeManager.h"

#import <MWFeedParser/NSString+HTML.h>
#import <XNGMarkdownParser/XNGMarkdownParser.h>

@implementation TGRedditMarkdownParser

+ (NSAttributedString *) attributedStringFromMarkdown:(NSString *)markdown
{
	markdown = [self removeTrailingNewlines:markdown];
	
	XNGMarkdownParser *parser = [XNGMarkdownParser new];
	parser.paragraphFont = [UIFont fontWithName:@"AvenirNext-Medium" size:15];
	parser.boldFontName = @"AvenirNext-DemiBold";
	parser.italicFontName = @"AvenirNext-MediumItalic";
	parser.boldItalicFontName = @"AvenirNext-DemiBoldItalic";
	parser.linkFontName = @"AvenirNext-DemiBold";
	parser.topAttributes = @{NSForegroundColorAttributeName : [ThemeManager colorForKey:kTGThemeTextColor]};
	
	NSAttributedString *attrStr = [parser attributedStringFromMarkdownString:markdown]; // TODO I think XNG allows you to set paragraph style on the parser instead
	
	attrStr = [self styleAttributedString:attrStr];
	
	return attrStr;
}

+ (NSAttributedString *) attributedStringFromHTML:(NSString *)html
{
	html = [self htmlStringFromEscapedHTML:html];
	html = [self styleHTML:html];
	
	NSData *htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
	NSAttributedString *attrStr = [[NSAttributedString alloc] initWithData:htmlData
																   options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
														documentAttributes:NULL error:NULL];

//	attrStr = [self styleAttributedString:attrStr];
	attrStr = [attrStr attributedSubstringFromRange:NSMakeRange(0, attrStr.length-1)];  // trim trailing newline
	
	return attrStr;
}

+ (NSString *) removeTrailingNewlines:(NSString *)string
{
	// trim trailing returns
	while ([string hasSuffix:@"\n"])
		string = [string substringToIndex:string.length-1];
	
	// replace 2+ consecutive returns with single new paragraphs
	while ([string rangeOfString:@"\n\n"].location != NSNotFound)
		string = [string stringByReplacingOccurrencesOfString:@"\n\n" withString:@"\n"];
	
	return string;
}

+ (NSString *) htmlStringFromEscapedHTML:(NSString *)string
{
	return [string stringByDecodingHTMLEntities]; // using <MWFeedParser/NSString+HTML.h> extension
}

+ (NSString *) styleHTML:(NSString *)bodyHTML
{
	NSString *wrapperHTMLPath = [[NSBundle mainBundle] pathForResource:@"markdownStyle" ofType:@"html"];
	NSString *wrapperHTML = [NSString stringWithContentsOfFile:wrapperHTMLPath encoding:NSUTF8StringEncoding error:nil];

	// replace #hexcolor names
	wrapperHTML = [wrapperHTML stringByReplacingOccurrencesOfString:@"textColor" withString:[ThemeManager stringForKey:kTGThemeTextColor]];
	wrapperHTML = [wrapperHTML stringByReplacingOccurrencesOfString:@"secondaryTextColor" withString:[ThemeManager stringForKey:kTGThemeSecondaryTextColor]];
	wrapperHTML = [wrapperHTML stringByReplacingOccurrencesOfString:@"tintColor" withString:[ThemeManager stringForKey:kTGThemeTintColor]];
	wrapperHTML = [wrapperHTML stringByReplacingOccurrencesOfString:@"smallcapsHeaderColor" withString:[ThemeManager stringForKey:kTGThemeSmallcapsHeaderColor]];
	
	// replace /r/ links
	bodyHTML = [bodyHTML stringByReplacingOccurrencesOfString:@"href=\"/r/" withString:[NSString stringWithFormat:@"href=\"%@", [[TGRedditClient sharedClient] urlToSubreddit:@""]]];
	// insert actual html
	bodyHTML = [wrapperHTML stringByReplacingOccurrencesOfString:@"<!-- BODY -->" withString:bodyHTML];
	
	return bodyHTML;
}

+ (NSAttributedString *) styleAttributedString:(NSAttributedString *)attributedString // TODO set line height while parsing lists and shit?
{
	CGFloat const fontSize = 15.0f;
	CGFloat const minLineheight = fontSize * 1.4;
	CGFloat const paragraphSpacing = fontSize * 0.4;
	CGFloat const firstTab = fontSize * 0.8;
	CGFloat const secondTab = fontSize * 2.3;
	
	NSMutableAttributedString *mutAttrStr = [attributedString mutableCopy];
	
	NSMutableParagraphStyle *bodyStyle = [NSMutableParagraphStyle new];
	[bodyStyle setMinimumLineHeight:minLineheight];
	[bodyStyle setParagraphSpacing:paragraphSpacing];
	
	[mutAttrStr addAttribute:NSParagraphStyleAttributeName
					   value:bodyStyle
					   range:NSMakeRange(0, mutAttrStr.length)];
	
	
	// style lists
	NSMutableParagraphStyle *listStyle = [bodyStyle mutableCopy];
	listStyle.paragraphSpacingBefore = fontSize * 0.2;
	listStyle.paragraphSpacing = fontSize * 0.6;
	listStyle.headIndent = secondTab;
	NSTextTab *listTab = [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentNatural
														 location:firstTab
														  options:nil];
	NSTextTab *listTab2 = [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentNatural
														 location:secondTab
														  options:nil];
	listStyle.tabStops = @[listTab, listTab2];
	
/**/
	NSInteger index = 0;
	NSMutableArray *listLineRanges = [NSMutableArray new];
	NSArray *lines = [[mutAttrStr string] componentsSeparatedByString:@"\n"];
	for (NSString *line in lines)
	{
		if ([line hasPrefix:@"\t"])
		{
			NSRange listLineRange = {index, line.length}; // subtract 1 from line length because we'll trim the ending \n
			[listLineRanges addObject:[NSValue valueWithRange:listLineRange]];
		}
		index += line.length + 1; // add extra one for missing \n
	}
	
	for (NSValue *rangeValue in listLineRanges) [mutAttrStr addAttribute:NSParagraphStyleAttributeName value:listStyle range:[rangeValue rangeValue]];
	
	/*
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\n\t.*" options:kNilOptions error:nil];
	
	NSRange range = NSMakeRange(0, [mutAttrStr string].length);
	
	[regex enumerateMatchesInString:[mutAttrStr string] options:kNilOptions range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
		
		NSRange subStringRange = [result rangeAtIndex:1];
		[mutableAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:subStringRange];
	}];*/
	
	NSAttributedString *result = [mutAttrStr attributedSubstringFromRange:NSMakeRange(0, mutAttrStr.length-1)];  // trim extra newline
	
	return result;
}

@end
