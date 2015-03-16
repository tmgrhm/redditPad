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

#import "TGRedditClient.h"
#import "TGComment.h"

#import <TSMarkdownParser/TSMarkdownParser.h>

@interface TGLinkViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *fadeView;
@property (weak, nonatomic) IBOutlet UITableView *commentTableView;

@property (strong, nonatomic) NSURL *urlFromCommentTapped;

@end

@implementation TGLinkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

	self.commentTableView.estimatedRowHeight = 80.0;
	self.commentTableView.rowHeight = UITableViewAutomaticDimension;
	
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
		if (comment) [comments addObject:comment];
	}
	
	self.comments = [NSArray arrayWithArray:comments];
	[self.commentTableView reloadData];
	
	NSLog(@"Found %lu comments", self.comments.count);
}

- (NSAttributedString *) commentBodyFromMarkdown:(NSString *)commentBody
{
	TSMarkdownParser *parser = [TSMarkdownParser standardParser];
	
	parser.paragraphFont = [UIFont systemFontOfSize:15];
	parser.strongFont = [UIFont boldSystemFontOfSize:15];
	parser.emphasisFont = [UIFont italicSystemFontOfSize:15];
	parser.h1Font = [UIFont boldSystemFontOfSize:25];
	parser.h2Font = [UIFont boldSystemFontOfSize:23];
	parser.h3Font = [UIFont boldSystemFontOfSize:21];
	parser.h4Font = [UIFont boldSystemFontOfSize:19];
	parser.h5Font = [UIFont boldSystemFontOfSize:17];
	parser.h6Font = [UIFont boldSystemFontOfSize:15];
	
	NSMutableAttributedString *string = [[parser attributedStringFromMarkdown:commentBody] mutableCopy];
	NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
	[paragraphStyle setLineSpacing:4.0];
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

#pragma mark - Table view data source

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
	
	TGComment *comment = ((TGComment *)self.comments[indexPath.row]);
	
	cell.body.attributedText = [self commentBodyFromMarkdown:comment.body];
	cell.body.delegate = self;
	
	cell.score.text = [NSString stringWithFormat:@"%lu points", (unsigned long) comment.score];
	cell.author.text = comment.author;
	
	return cell;
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
