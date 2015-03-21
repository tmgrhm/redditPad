//
//  TGLinkViewController.m
//  redditPad
//
//  Created by Tom Graham on 13/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGLinkViewController.h"
#import "TGWebViewController.h"
#import "TGCommentTableViewCell.h"
#import "TGLinkHeaderContainerViewController.h"
#import "TGSelfpostView.h"

#import "TGRedditClient.h"
#import "TGComment.h"

#import <XNGMarkdownParser/XNGMarkdownParser.h>

@interface TGLinkViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *fadeView;
@property (weak, nonatomic) IBOutlet UITableView *commentTableView;
@property (strong, nonatomic) TGCommentTableViewCell *sizingCell;

@property (strong, nonatomic) NSMutableDictionary *commentHeights;
@property (strong, nonatomic) NSMutableArray *collapsedComments;

@property (strong, nonatomic) NSURL *urlFromCommentTapped;

@end

@implementation TGLinkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

//	self.commentTableView.estimatedRowHeight = 80.0;
	self.commentTableView.rowHeight = UITableViewAutomaticDimension;
	self.sizingCell = [TGCommentTableViewCell new];
	
	self.collapsedComments = [NSMutableArray new];
	self.commentHeights = [NSMutableDictionary new];
	
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

- (void) commentsFromResponse:(NSArray *)responseArray
{
	NSMutableArray *comments = [NSMutableArray new];
	
	for (id dict in responseArray)
	{
		TGComment *comment = [[TGComment new] initCommentFromDictionary:dict];
		
		if (comment)
		{
			comments = (NSMutableArray *) [comments arrayByAddingObjectsFromArray:[self childrenCommentsForComment:comment]];
		}
	}
	
	self.comments = [NSArray arrayWithArray:comments];
	
	[self reloadCommentTableViewData];
	
	NSLog(@"Found %lu comments", self.comments.count);
}

- (NSMutableArray *) childrenCommentsForComment:(TGComment *)comment
{
	NSMutableArray *comments = [NSMutableArray new];

	[comments addObject:comment];
	if (comment.children.count > 0)
	{
		for (TGComment *child in comment.children)
		{
			comments = (NSMutableArray *) [comments arrayByAddingObjectsFromArray:[self childrenCommentsForComment:child]];
		}
	}
	
	return comments;
}

- (NSAttributedString *) commentBodyFromMarkdown:(NSString *)commentBody
{
	
	XNGMarkdownParser *parser = [XNGMarkdownParser new];
	
	parser.paragraphFont = [UIFont systemFontOfSize:15];
	parser.boldFontName = [UIFont boldSystemFontOfSize:15].fontName;
	parser.italicFontName = [UIFont italicSystemFontOfSize:15].fontName;
//	parser.h1font = [UIFont boldSystemFontOfSize:25];
//	parser.h2Font = [UIFont boldSystemFontOfSize:23];
//	parser.h3Font = [UIFont boldSystemFontOfSize:21];
//	parser.h4Font = [UIFont boldSystemFontOfSize:19];
//	parser.h5Font = [UIFont boldSystemFontOfSize:17];
//	parser.h6Font = [UIFont boldSystemFontOfSize:15];
	
	NSMutableAttributedString *string = [[parser attributedStringFromMarkdownString:commentBody] mutableCopy]; // TODO I think XNG allows you to set paragraph style on the parser instead
	NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
	[paragraphStyle setLineSpacing:4.0]; // TODO look at NSMutableString's LineHeight property (inspect NSAttributedString at runtime to see — e.g. "LineHeight 0/0")
	[paragraphStyle setParagraphSpacing:0]; // TODO add pargraph parsing to comment body? hard line break (two returns) turns into \n\n in comment[@"body"]
	
	[string addAttribute:NSParagraphStyleAttributeName
				   value:paragraphStyle
				   range:NSMakeRange(0, string.length)];
	
	return string;
}

- (void) configureCell:(TGCommentTableViewCell *)cell atIndex:(NSIndexPath *)indexPath
{
	TGComment *comment = ((TGComment *)self.comments[indexPath.row]);
	
	NSAttributedString *attributedMarkdown = [self commentBodyFromMarkdown:comment.body];
	cell.body.attributedText = attributedMarkdown; // TODO wtf exc_bad_access sometimes even though all appear alive
	cell.body.delegate = self;
	if ([self.collapsedComments containsObject:comment])
	{
		cell.body.textContainer.maximumNumberOfLines = 1;
	}
	
	cell.score.text = [NSString stringWithFormat:@"%lu points", (unsigned long) comment.score];
	cell.author.text = comment.author;
	
	cell.indentationLevel = comment.indentationLevel;
	cell.leftMargin.constant = cell.originalLeftMargin + (cell.indentationLevel * cell.indentationWidth);
	
	cell.backgroundColor = [self.collapsedComments containsObject:comment] ? [UIColor colorWithHue:0.583 saturation:0.025 brightness:0.941 alpha:1] : [UIColor whiteColor]; // TODO collapsing
}

- (CGFloat)calculateHeightForConfiguredSizingCell:(TGCommentTableViewCell *)sizingCell
{
	//Force the cell to update its constraints
	[sizingCell setNeedsLayout];
	[sizingCell layoutIfNeeded];
	
	// Get the size of the 'squashed' cell and return it to caller
	CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
	return size.height;
}

#pragma mark - UITextView Delegate
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)url inRange:(NSRange)characterRange
{
	self.urlFromCommentTapped = url;
	[self performSegueWithIdentifier:@"commentLinkTapped" sender:self];
	return NO; // TODO ???
}

#pragma mark - Table view
- (void) reloadCommentTableViewData
{
	[self.commentTableView beginUpdates];
	[self.commentTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
	[self.commentTableView endUpdates];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// Return the number of sections.
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// Return the number of rows in the section.
	return self.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	// Configure the cell...
	TGCommentTableViewCell *cell = [self.commentTableView dequeueReusableCellWithIdentifier:@"TGCommentTableViewCell" forIndexPath:indexPath];
	[self configureCell:cell atIndex:indexPath];
		
	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   [tableView deselectRowAtIndexPath:indexPath animated:TRUE];
	
	// TODO collapsing
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

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	TGComment *comment = self.comments[indexPath.row];
	CGFloat height;
	if ((height = [[self.commentHeights objectForKey:comment.id] floatValue]))
	{
		return height;
	}

	// In here I create a cell and configure it with a cell identifier
/*	static TGCommentTableViewCell *sizingCell = nil; // TODO create a new cell instead of dequeueing from tableview?
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sizingCell = [self.commentTableView dequeueReusableCellWithIdentifier:@"TGCommentTableViewCell"];
	});*/
	
	TGCommentTableViewCell *sizingCell = self.sizingCell;

	// This configures the sizing cell labels with text values
	[self configureCell:sizingCell atIndex:indexPath];

	// This line calls the calculation. It fires the Auto Layout constraints on the cell,
	// If label 2 and / or label 3 are empty, they will be collapsed to 0 height.
	height = [self calculateHeightForConfiguredSizingCell:sizingCell];
	[self.commentHeights setValue:[NSNumber numberWithFloat:height] forKey:comment.id];

	return height;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
	
	if ([segue.identifier isEqualToString:@"embedLinkHeaderController"]) // TODO RECENT make header VC
	{
		TGLinkHeaderContainerViewController *headerVC = segue.destinationViewController;
		headerVC.link = self.link;
	}
	else if ([segue.identifier isEqualToString:@"linkViewToWebView"])
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
