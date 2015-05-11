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

- (void)awakeFromNib
{
	self.originalLeftMargin = self.leftMargin.constant;
	self.bodyLabel.textContainerInset = UIEdgeInsetsMake(-2, -4, 0, 0);
	
	self.backgroundColor = [ThemeManager contentBackgroundColor];
}

- (void) setIndentationLevel:(NSInteger)indentationLevel
{
	[super setIndentationLevel:indentationLevel];
	
	// increase left margin
	self.leftMargin.constant = self.originalLeftMargin + (self.indentationLevel * self.indentationWidth);
	
	// add indentation lines
	if (self.indentationLevel > 0)
	{
		self.indentationLines = [NSMutableArray new];
		
		UIBezierPath *path = [UIBezierPath bezierPath];
		[path moveToPoint:CGPointMake(0, 0)];
		[path addLineToPoint:CGPointMake(0, self.contentView.frame.size.height)];
		[path closePath];
		CGPathRef cgPath = path.CGPath;
		
		for (int i=1; i <= self.indentationLevel; i++)
		{
			CAShapeLayer *shapeLayer = [CAShapeLayer layer];
			shapeLayer.path = cgPath;
			shapeLayer.strokeColor = [ThemeManager separatorColor].CGColor;
			shapeLayer.lineWidth = 1.0;
			
			CGFloat lineX = i * self.indentationWidth;
			shapeLayer.position = CGPointMake(lineX, 0.0);
			
			[self.layer addSublayer:shapeLayer];
			[self.indentationLines addObject:shapeLayer];
		}
	}
}

- (void) setBackgroundColor:(UIColor *)backgroundColor
{
	[super setBackgroundColor:backgroundColor];
	
	self.contentView.backgroundColor = backgroundColor;
	self.bodyLabel.backgroundColor = backgroundColor;
	self.authorLabel.backgroundColor = backgroundColor;
	self.pointsLabel.backgroundColor = backgroundColor;
	self.timestampLabel.backgroundColor = backgroundColor;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setCollapsed:(BOOL)collapsed
{
	_collapsed = collapsed;

	if (self.isCollapsed) // TODO
	{
		self.backgroundColor = [ThemeManager hiddenCommentBackground];
	}
	else
	{
		self.backgroundColor = [ThemeManager contentBackgroundColor];
	}
}

- (void) prepareForReuse
{
	for (CALayer *layer in self.indentationLines) [layer removeFromSuperlayer];

	self.collapsed = NO;
}

@end
