//
//  TGCommentTableViewCell.m
//  redditPad
//
//  Created by Tom Graham on 13/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGCommentTableViewCell.h"

#import "ThemeManager.h"

@interface TGCommentTableViewCell ()

@property (strong, nonatomic) NSMutableArray *indentationLines;

@end

@implementation TGCommentTableViewCell

- (void)awakeFromNib {
    // Initialization code
	self.originalLeftMargin = self.leftMargin.constant;
	self.bodyLabel.textContainerInset = UIEdgeInsetsMake(-2, -4, 0, 0); // TODO
}

- (void) setIndentationLevel:(NSInteger)indentationLevel
{
	[super setIndentationLevel:indentationLevel];
	
	// increase left margin
	self.leftMargin.constant = self.originalLeftMargin + (self.indentationLevel * self.indentationWidth);
	
	// add indentation lines
	self.indentationLines = [NSMutableArray new];
	if (self.indentationLevel > 0)
	{
		for (int i=1; i <= self.indentationLevel; i++)
		{
			UIView *indentLine = [UIView new];
			[indentLine setBackgroundColor:[ThemeManager separatorColor]];
			
			CGFloat lineX = i * self.indentationWidth;
			indentLine.frame = CGRectMake(lineX, 0.0f, 1.0f, self.contentView.frame.size.height);
			
			[self.indentationLines addObject:indentLine];
			[self.contentView addSubview:indentLine];
		}
	}
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) prepareForReuse
{
	for (UIView *view in self.indentationLines) [view removeFromSuperview];
}

@end
