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
@property (weak, nonatomic) IBOutlet UIView *shadowView;
@property (weak, nonatomic) IBOutlet UITableView *commentTableView;

@property (strong, nonatomic) TGCommentTableViewCell *sizingCell;

@property (strong, nonatomic) NSMutableDictionary *commentHeights;
@property (strong, nonatomic) NSMutableArray *collapsedComments;

@property (strong, nonatomic) NSURL *urlFromCommentTapped;

@end

@implementation TGLinkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[self createShadow];
	
//	self.commentTableView.estimatedRowHeight = 80.0;
//	self.commentTableView.rowHeight = UITableViewAutomaticDimension;

	self.collapsedComments = [NSMutableArray new];
	self.commentHeights = [NSMutableDictionary new];
	
	__weak __typeof(self)weakSelf = self;
	[[TGRedditClient sharedClient] requestCommentsForLink:self.link withCompletion:^(NSArray *comments)
	 {
		 [weakSelf commentsFromResponse:comments];
	 }];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closePressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)createShadow {
	// Do any additional setup after loading the view.
	
	CALayer *containerCALayer = self.shadowView.layer;
	containerCALayer.borderColor = [[UIColor colorWithRed:0.776 green:0.788 blue:0.8 alpha:0.6] CGColor];
	containerCALayer.borderWidth = 0.5f;
	// TODO get a performant shadow
//	containerCALayer.shadowOffset = CGSizeMake(0, 1);
//	containerCALayer.shadowColor = [[UIColor colorWithRed:0.776 green:0.788 blue:0.8 alpha:0.5] CGColor];
//	containerCALayer.shadowRadius = 6.0f;
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

#pragma mark - UITextView Delegate
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)url inRange:(NSRange)characterRange
{
	self.urlFromCommentTapped = url;
	[self performSegueWithIdentifier:@"commentLinkTapped" sender:self];
	return NO; // TODO ???
}

#pragma mark - Table view
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
	TGCommentTableViewCell *cell = [self.commentTableView dequeueReusableCellWithIdentifier:@"TGCommentTableViewCell" forIndexPath:indexPath];
	[self configureCell:cell atIndex:indexPath];
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	TGComment *comment = self.comments[indexPath.row];
	CGFloat height;
	
	if ((height = [[self.commentHeights objectForKey:comment.id] floatValue]))
	{
		return height;
	}
	
	if (!self.sizingCell)
	{
		self.sizingCell	= [self.commentTableView dequeueReusableCellWithIdentifier:@"TGCommentTableViewCell"];
	}
	
	[self configureCell:self.sizingCell atIndex:indexPath];
	
	[self.sizingCell setNeedsUpdateConstraints];
	[self.sizingCell updateConstraintsIfNeeded];
	self.sizingCell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(self.sizingCell.bounds));
	
	height = [self calculateHeightForConfiguredSizingCell:self.sizingCell];
	[self.commentHeights setValue:@(height) forKey:comment.id];
	
	// +1 for the separator
	height += 1.0f;
	
	return height;
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

- (void) reloadCommentTableViewData
{
	[self.commentTableView beginUpdates];
	[self.commentTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
	[self.commentTableView endUpdates];
}

- (void) configureCell:(TGCommentTableViewCell *)cell atIndex:(NSIndexPath *)indexPath
{
	TGComment *comment = ((TGComment *)self.comments[indexPath.row]);
	
	cell.body.attributedText = [self attributedStringFromMarkdown:comment.body];
	cell.body.delegate = self;
	//	if ([self.collapsedComments containsObject:comment])
	//	{
	//		cell.body.textContainer.maximumNumberOfLines = 1; //  TOOD reenable at some point
	//	}
	
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
	
	CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
	return size.height;
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
