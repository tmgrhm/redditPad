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
	
	NSMutableAttributedString *string = [[parser attributedStringFromMarkdownString:markdown] mutableCopy]; // TODO I think XNG allows you to set paragraph style on the parser instead
	NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
	[paragraphStyle setMinimumLineHeight:21.0];
	[paragraphStyle setParagraphSpacing:6.0];
	
	[string addAttribute:NSParagraphStyleAttributeName
				   value:paragraphStyle
				   range:NSMakeRange(0, string.length)];
	
	return string;
}

+ (NSAttributedString *) attributedStringFromHTML:(NSString *)html
{
	html = [self htmlStringFromEscapedHTML:html];
	html = [self styleHTML:html];
	
	NSAttributedString *attrStr = [[NSAttributedString alloc] initWithData:[html dataUsingEncoding:NSUTF8StringEncoding]
																   options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
														documentAttributes:NULL error:NULL];
	attrStr = [attrStr attributedSubstringFromRange:NSMakeRange(0, attrStr.length-1)];
	
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

@end
