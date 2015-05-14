//
//  TGRedditMarkdownParser.h
//  redditPad
//
//  Created by Tom Graham on 14/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TGRedditMarkdownParser : NSObject

+ (NSAttributedString *) attributedStringFromMarkdown:(NSString *)markdown;

+ (NSAttributedString *) attributedStringFromHTML:(NSString *)html;

@end