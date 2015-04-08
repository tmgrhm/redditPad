//
//  TGPostViewController.m
//  redditPad
//
//  Created by Tom Graham on 23/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGPostViewController.h"

#import "TGWebViewController.h"

#import "ThemeManager.h"

#import "TGRedditClient.h"
#import "TGLinkPostCell.h"
#import "TGComment.h"
#import "TGCommentTableViewCell.h"

#import "NSDate+RelativeDateString.h"

#import <XNGMarkdownParser/XNGMarkdownParser.h>

@interface TGPostViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (strong, nonatomic) TGCommentTableViewCell *sizingCell;
@property (weak, nonatomic) IBOutlet UITableView *commentTableView;
@property (weak, nonatomic) IBOutlet UIView *shadowView;
@property (weak, nonatomic) IBOutlet UIView *fadeView;
@property (weak, nonatomic) IBOutlet UIToolbar *topToolbar;

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
	[self themeAppearance];
	
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

#pragma mark - Setup & Customisation

- (void)createShadow
{
	CALayer *containerCALayer = self.shadowView.layer;
	containerCALayer.borderColor = [[ThemeManager shadowBorderColor] CGColor];
	containerCALayer.borderWidth = 0.6f;
	// TODO get a performant shadow
	CGRect bounds = self.shadowView.bounds;
	bounds = CGRectMake(bounds.origin.x, bounds.origin.y + 2, bounds.size.width, bounds.size.height);
	containerCALayer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:containerCALayer.cornerRadius].CGPath;
	containerCALayer.shadowColor = [[ThemeManager shadowColor] CGColor];
	containerCALayer.shadowOpacity = 0.5f;
	containerCALayer.shadowRadius = 6.0f;
	
	self.fadeView.backgroundColor = [ThemeManager shadeColor];
	self.fadeView.alpha = 0.7f;
}

- (void) themeAppearance
{
	// empty
}

#pragma mark - IBActions

- (IBAction)closePressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)titlePressed:(id)sender {
	[self performSegueWithIdentifier:@"linkViewToWebView" sender:self];
}

#pragma mark - TableView


- (void) reloadCommentTableViewData
{
	[self.commentTableView beginUpdates];
	[self.commentTableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
	[self.commentTableView endUpdates];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section) {
		case 0: return 1;
		case 1: return self.comments.count;
		default: return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch(indexPath.section) {
		case 0: return [self postHeaderCell];
		case 1: return [self commentCellAtIndexPath:indexPath];
		default: return nil;
	}
}

- (TGLinkPostCell *) postHeaderCell
{
	TGLinkPostCell *cell = [self.commentTableView dequeueReusableCellWithIdentifier:@"TGLinkPostCell"];
	[self configureHeaderCell:cell];
	
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	
	return cell;
}

- (void) configureHeaderCell:(TGLinkPostCell *)cell
{
	// clear the delegates to prevent crashes — TODO solve?
	cell.title.delegate = self;
	cell.content.delegate = self;
	
	cell.title.selectable = YES; // enable selection while using UITextView setText else attributedText is reset (wtf)
	cell.title.text = self.link.title;
	NSMutableAttributedString *mutAttrTitle = [cell.title.attributedText mutableCopy];
	[mutAttrTitle addAttribute:NSForegroundColorAttributeName
						 value:[ThemeManager textColor]
						 range:NSMakeRange(0, mutAttrTitle.length)];
	cell.title.attributedText = mutAttrTitle;
	cell.title.selectable = NO;
	
	NSString *edited = [self.link isEdited] ? [NSString stringWithFormat:@" (edited %@)", [self.link.editDate relativeDateString]] : @""; // TODO better edit indicator
	cell.metadata.text = [NSString stringWithFormat:@"%ld points in /r/%@ %@%@, by %@", (long)self.link.score, self.link.subreddit, [self.link.creationDate relativeDateString], edited, self.link.author];
	cell.metadata.textColor = [ThemeManager secondaryTextColor];
	
	cell.numComments.text = [NSString stringWithFormat:@"%lu COMMENTS", (unsigned long)self.link.totalComments];
	cell.numComments.textColor = [ThemeManager smallcapsHeaderColor];
	cell.numComments.alpha = 0.5f;
	
	cell.separator.backgroundColor = [ThemeManager backgroundColor];
	
	if ([self.link isSelfpost]) {
		cell.content.attributedText = [self attributedStringFromMarkdown:self.link.selfText];
	} else {
		cell.content.text = [self.link.url absoluteString];
	}
}

- (TGCommentTableViewCell *)commentCellAtIndexPath:(NSIndexPath *)indexPath
{
	TGCommentTableViewCell *cell = [self.commentTableView dequeueReusableCellWithIdentifier:@"TGCommentTableViewCell" forIndexPath:indexPath];
	[self configureCommentCell:cell atIndexPath:indexPath];
	
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	
	return cell;
}

- (void)configureCommentCell:(TGCommentTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	TGComment *comment = self.comments[indexPath.row];
	
	cell.bodyLabel.delegate = self;	// re-set the delegate *before* setting attrText to prevent null delegate crash
	NSAttributedString *attrBody = [self attributedStringFromMarkdown:comment.body];
	[cell.bodyLabel setAttributedText:attrBody];
	
	[cell.authorLabel setText:comment.author];
	if ([comment.author isEqualToString:self.link.author])
	{
		cell.authorLabel.text = [cell.authorLabel.text stringByAppendingString:@" (OP)"]; // TODO
		cell.authorLabel.textColor = [ThemeManager tintColor];
	} else {
		cell.authorLabel.textColor = [ThemeManager textColor];
	}
	
	[cell.pointsLabel setText:[NSString stringWithFormat:@"%ld points", (long)comment.score]];
	
	NSString *edited = [comment isEdited] ? [NSString stringWithFormat:@" (edited %@)", [comment.editDate relativeDateString]] : @""; // TODO better edit indicator
	[cell.timestampLabel setText:[NSString stringWithFormat:@"%@%@", [comment.creationDate relativeDateString], edited]];
	
	cell.indentationLevel = comment.indentationLevel;
	cell.leftMargin.constant = cell.originalLeftMargin + (cell.indentationLevel * cell.indentationWidth);
	
	cell.pointsLabel.textColor = [ThemeManager secondaryTextColor];
	cell.timestampLabel.textColor = [ThemeManager secondaryTextColor];
	
	if ([self.collapsedComments containsObject:comment])
	{
		cell.backgroundColor = [ThemeManager backgroundColor];
//		cell.bodyLabel.numberOfLines = 1;
	}
	else
	{
		cell.backgroundColor = [ThemeManager contentBackgroundColor];
//		cell.bodyLabel.numberOfLines = 0;
	}
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch(indexPath.section) {
		case 0: return [self heightForHeaderCell];
		case 1: return [self heightForCommentCellAtIndexPath:indexPath];
		default: return 0;
	}
}

- (CGFloat)heightForHeaderCell
{
	static TGLinkPostCell *sizingCell = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sizingCell = [self.commentTableView dequeueReusableCellWithIdentifier:@"TGLinkPostCell"];
	});

	[self configureHeaderCell:sizingCell];
	
	sizingCell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.commentTableView.frame), CGRectGetHeight(sizingCell.bounds));
	
	// constrain contentView.width to same as table.width
	// required for correct height calculation with UITextView
	// http://stackoverflow.com/questions/27064070/
	UIView *contentView = sizingCell.contentView;
	contentView.translatesAutoresizingMaskIntoConstraints = NO;
	NSDictionary *metrics = @{@"tableWidth":@(self.commentTableView.frame.size.width)};
	NSDictionary *views = NSDictionaryOfVariableBindings(contentView);
	[contentView addConstraints:
	 [NSLayoutConstraint constraintsWithVisualFormat:@"[contentView(tableWidth)]"
											 options:0
											 metrics:metrics
											   views:views]];
	
	[sizingCell setNeedsLayout];
	[sizingCell layoutIfNeeded];
	CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
	
	return size.height + 1.0f; // Add 1.0f for the cell separator height
}

- (CGFloat)heightForCommentCellAtIndexPath:(NSIndexPath *)indexPath
{
	TGComment *comment = self.comments[indexPath.row];
	CGFloat height;
	if ((height = [[self.commentHeights objectForKey:comment.id] floatValue]))
	{
		return height; // if cached, return cached height
	}
	
	static TGCommentTableViewCell *sizingCell = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sizingCell = [self.commentTableView dequeueReusableCellWithIdentifier:@"TGCommentTableViewCell"];
	});
 
	[self configureCommentCell:sizingCell atIndexPath:indexPath];
	
	height = [self calculateHeightForConfiguredCommentCell:sizingCell];
	[self.commentHeights setValue:@(height) forKey:comment.id]; // cache it
	return height;
}

- (CGFloat)calculateHeightForConfiguredCommentCell:(TGCommentTableViewCell *)sizingCell
{
	sizingCell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.commentTableView.frame), CGRectGetHeight(sizingCell.bounds));

	// constrain contentView.width to same as table.width
	// required for correct height calculation with UITextView
	// http://stackoverflow.com/questions/27064070/
	UIView *contentView = sizingCell.contentView;
	contentView.translatesAutoresizingMaskIntoConstraints = NO;
	NSDictionary *metrics = @{@"tableWidth":@(self.commentTableView.frame.size.width)};
	NSDictionary *views = NSDictionaryOfVariableBindings(contentView);
	[contentView addConstraints:
	 [NSLayoutConstraint constraintsWithVisualFormat:@"[contentView(tableWidth)]"
											 options:0
											 metrics:metrics
											   views:views]];
	
	[sizingCell setNeedsLayout];
	[sizingCell layoutIfNeeded];
	CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
	
	return size.height + 1.0f; // Add 1.0f for the cell separator height
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:TRUE];
	
	
	switch(indexPath.section) {
		case 1:
		{
			// TODO header tapped
		}
		case 2:
		{
			[self collapseCommentsAtIndexPath:indexPath];
		}
	}
}

- (void) collapseCommentsAtIndexPath:(NSIndexPath *)indexPath	// TODO look at using beginUpdates endUpdates instead of reloadData so only the relevant comments animate
{
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

#pragma mark - UITextView
- (BOOL) textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
	self.urlFromCommentTapped = URL;
	[self performSegueWithIdentifier:@"openLink" sender:self];
	return NO;
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
	else if ([segue.identifier isEqualToString:@"openLink"])
	{
		TGWebViewController *webVC = segue.destinationViewController;
		webVC.url = self.urlFromCommentTapped;
	}
}

#pragma mark - Utility

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

- (NSAttributedString *) attributedStringFromMarkdown:(NSString *)markdown
{
	// remove trailing newlines
	NSString *newMarkdown = markdown;
	while ([newMarkdown hasSuffix:@"\n"])
		newMarkdown = [newMarkdown substringToIndex:newMarkdown.length-1];
	// replace 2+ consecutive returns with single new paragraphs
	while ([newMarkdown rangeOfString:@"\n\n"].location != NSNotFound)
	{
		newMarkdown = [newMarkdown stringByReplacingOccurrencesOfString:@"\n\n" withString:@"\n"];
	}
	markdown = newMarkdown;
	
	XNGMarkdownParser *parser = [XNGMarkdownParser new];
	parser.paragraphFont = [UIFont fontWithName:@"AvenirNext-Medium" size:15];
	parser.boldFontName = @"AvenirNext-DemiBold";
	parser.italicFontName = @"AvenirNext-MediumItalic";
	parser.boldItalicFontName = @"AvenirNext-DemiBoldItalic";
	parser.linkFontName = @"AvenirNext-DemiBold";
	parser.topAttributes = @{NSForegroundColorAttributeName : [ThemeManager textColor]};
	
	NSMutableAttributedString *string = [[parser attributedStringFromMarkdownString:markdown] mutableCopy]; // TODO I think XNG allows you to set paragraph style on the parser instead
	NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
	//	[paragraphStyle setLineSpacing:4.0]; // TODO look at NSMutableString's LineHeight property (inspect NSAttributedString at runtime to see — e.g. "LineHeight 0/0")
	[paragraphStyle setMinimumLineHeight:21.0];
	[paragraphStyle setParagraphSpacing:6.0];
	
	[string addAttribute:NSParagraphStyleAttributeName
				   value:paragraphStyle
				   range:NSMakeRange(0, string.length)];
	
	return string;
}

@end
