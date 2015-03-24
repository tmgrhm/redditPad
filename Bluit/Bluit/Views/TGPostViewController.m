//
//  TGPostViewController.m
//  redditPad
//
//  Created by Tom Graham on 23/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGPostViewController.h"

#import "TGWebViewController.h"

#import "TGRedditClient.h"
#import "TGComment.h"
#import "TGCommentCell.h"

#import <XNGMarkdownParser/XNGMarkdownParser.h>

@interface TGPostViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (strong, nonatomic) TGCommentCell *sizingCell;
@property (weak, nonatomic) IBOutlet UITableView *commentTableView;
@property (weak, nonatomic) IBOutlet UIView *shadowView;

@property (strong, nonatomic) NSArray *comments;
@property (strong, nonatomic) NSMutableArray *collapsedComments;
@property (strong, nonatomic) NSMutableDictionary *commentHeights;

@property (strong, nonatomic) NSURL *urlFromCommentTapped;

- (void) reloadCommentTableViewData;

@end

@implementation TGPostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	self.collapsedComments = [NSMutableArray new];
	self.commentHeights = [NSMutableDictionary new];
	
	[self createShadow];
	
	__weak __typeof(self)weakSelf = self;
	[[TGRedditClient sharedClient] requestCommentsForLink:self.link withCompletion:^(NSArray *comments)
	 {
		 [weakSelf commentsFromResponse:comments];
	 }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closePressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)createShadow
{
	CALayer *containerCALayer = self.shadowView.layer;
	containerCALayer.borderColor = [[UIColor colorWithRed:0.776 green:0.788 blue:0.8 alpha:0.6] CGColor];
	containerCALayer.borderWidth = 0.5f;
	// TODO get a performant shadow
	//	containerCALayer.shouldRasterize = YES;
	//	containerCALayer.rasterizationScale = UIScreen.mainScreen.scale;
	containerCALayer.shadowColor = [[UIColor colorWithRed:0.776 green:0.788 blue:0.8 alpha:1] CGColor];
	containerCALayer.shadowOpacity = 0.5f;
	containerCALayer.shadowRadius = 6.0f;
	CGRect bounds = self.shadowView.bounds;
	bounds = CGRectMake(bounds.origin.x, bounds.origin.y + 1, bounds.size.width, bounds.size.height);
	containerCALayer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:containerCALayer.cornerRadius].CGPath;
}

- (void) commentsFromResponse:(NSArray *)responseArray
{
	NSMutableArray *comments = [NSMutableArray array];
	
	for (id dict in responseArray)
	{
		TGComment *comment = [[TGComment new] initCommentFromDictionary:dict];
		
		if (comment)
		{
			[comments addObject:comment];
			comments = [[comments arrayByAddingObjectsFromArray:[TGComment childrenRecursivelyForComment:comment]] mutableCopy];
		}
	}
	
	self.comments = [NSArray arrayWithArray:comments];
	
	[self reloadCommentTableViewData];
	
	NSLog(@"Found %lu comments", self.comments.count);
}

- (NSAttributedString *) attributedStringFromMarkdown:(NSString *)commentBody
{
	XNGMarkdownParser *parser = [XNGMarkdownParser new];
	
	parser.paragraphFont = [UIFont systemFontOfSize:15];
	parser.boldFontName = [UIFont boldSystemFontOfSize:15].fontName;
	parser.italicFontName = [UIFont italicSystemFontOfSize:15].fontName;
	
	NSMutableAttributedString *string = [[parser attributedStringFromMarkdownString:commentBody] mutableCopy]; // TODO I think XNG allows you to set paragraph style on the parser instead
	NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
	[paragraphStyle setLineSpacing:4.0]; // TODO look at NSMutableString's LineHeight property (inspect NSAttributedString at runtime to see — e.g. "LineHeight 0/0")
	[paragraphStyle setParagraphSpacing:0]; // TODO add pargraph parsing to comment body? hard line break (two returns) turns into \n\n in comment[@"body"]
	
	[string addAttribute:NSParagraphStyleAttributeName
				   value:paragraphStyle
				   range:NSMakeRange(0, string.length)];
	
	return string;
}


- (void) reloadCommentTableViewData
{
	[self.commentTableView beginUpdates];
	[self.commentTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
	[self.commentTableView endUpdates];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [self commentCellAtIndexPath:indexPath];
}

- (TGCommentCell *)commentCellAtIndexPath:(NSIndexPath *)indexPath
{
	TGCommentCell *cell = [self.commentTableView dequeueReusableCellWithIdentifier:@"TGCommentCell" forIndexPath:indexPath];
	[self configureCommentCell:cell atIndexPath:indexPath];
	
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
//	NSLog(@"commentCellAtIndexPath: %f, %f, %@", cell.bodyLabel.frame.size.height, cell.bodyLabel.frame.size.width, cell.authorLabel.text);
	
	return cell;
}

- (void)configureCommentCell:(TGCommentCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	TGComment *comment = self.comments[indexPath.row];
	NSAttributedString *attrBody = [self attributedStringFromMarkdown:comment.body];
	[cell.bodyLabel setAttributedText:attrBody];
	
	[cell.authorLabel setText:comment.author];
	[cell.pointsLabel setText:[NSString stringWithFormat:@"%lu points", comment.score]];
	
	cell.backgroundColor = [self.collapsedComments containsObject:comment] ? [UIColor colorWithHue:0.583 saturation:0.025 brightness:0.941 alpha:1] : [UIColor whiteColor];

	[cell.timestampLabel setText:[NSString stringWithFormat:@"%lu", comment.indentationLevel]]; // TODO update
	
	cell.indentationLevel = comment.indentationLevel;
	cell.leftMargin.constant = cell.originalLeftMargin + (cell.indentationLevel * cell.indentationWidth);
//	NSLog(@"configureCell:        %f, %f, %@", cell.bodyLabel.frame.size.height, cell.bodyLabel.frame.size.width, comment.author);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [self heightForCommentCellAtIndexPath:indexPath];
}

- (CGFloat)heightForCommentCellAtIndexPath:(NSIndexPath *)indexPath
{
	TGComment *comment = self.comments[indexPath.row];
	CGFloat height;
	if ((height = [[self.commentHeights objectForKey:comment.id] floatValue])) // if cached, return cached height
	{
		return height;
	}
	
	static TGCommentCell *sizingCell = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sizingCell = [self.commentTableView dequeueReusableCellWithIdentifier:@"TGCommentCell"];
	});
 
	[self configureCommentCell:sizingCell atIndexPath:indexPath];
	
	height = [self calculateHeightForConfiguredSizingCell:sizingCell];
//	NSLog(@"sizingCell: %f, %f, %@", sizingCell.bodyLabel.frame.size.height, sizingCell.bodyLabel.frame.size.width, comment.author);
	[self.commentHeights setValue:@(height) forKey:comment.id]; // cache it
	return height;
}

- (CGFloat)calculateHeightForConfiguredSizingCell:(UITableViewCell *)sizingCell
{
	sizingCell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.commentTableView.frame), CGRectGetHeight(sizingCell.bounds));
	
	[sizingCell setNeedsLayout];
	[sizingCell layoutIfNeeded];
 
	CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
	return size.height + 1.0f; // Add 1.0f for the cell separator height
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:TRUE];
	
	TGComment *comment = self.comments[indexPath.row];
	NSMutableArray *newComments = [self.comments mutableCopy];
	NSArray *children = [TGComment childrenRecursivelyForComment:comment];
	
	if ([self.collapsedComments containsObject:comment])
	{
		[self.collapsedComments removeObject:comment];
		NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(indexPath.row+1, children.count)];
		[newComments insertObjects:children atIndexes:indexes];
		
		for (TGComment *child in children)
		{
			if ([self.collapsedComments containsObject:child])
				[newComments removeObjectsInArray:[TGComment childrenRecursivelyForComment:child]];
		}
	}
	else
	{
		[self.collapsedComments addObject:comment];
		[newComments removeObjectsInArray:children];
	}
	
	self.comments = newComments;
	[self reloadCommentTableViewData];
}


#pragma mark - Navigation

 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
	
	if ([segue.identifier isEqualToString:@"linkViewToWebView"])
	{
		TGWebViewController *webVC = segue.destinationViewController;
		webVC.link = self.link;
	}
	else if ([segue.identifier isEqualToString:@"commentLinkTapped"])
	{
		TGWebViewController *webVC = segue.destinationViewController;
		webVC.url = self.urlFromCommentTapped;
	}
 }


@end
