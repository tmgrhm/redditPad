//
//  TGCommentTableViewController.m
//  redditPad
//
//  Created by Tom Graham on 13/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGCommentTableViewController.h"
#import "TGComment.h"
#import "TGCommentTableViewCell.h"
#import "TGRedditClient.h"

@interface TGCommentTableViewController ()

@end

@implementation TGCommentTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.tableView.estimatedRowHeight = 80.0;
	self.tableView.rowHeight = UITableViewAutomaticDimension;
	
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

- (void) commentsFromResponse:(NSArray *)responseArray
{
	NSMutableArray *comments = [NSMutableArray new];
	
	for (id dict in responseArray)
	{
		TGComment *comment = [[TGComment new] initCommentFromDictionary:dict];
		if (comment) [comments addObject:comment];
	}
	
	self.comments = [NSArray arrayWithArray:comments];
	[self.tableView reloadData];
	
	NSLog(@"Found %lu comments", self.comments.count);
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
	TGCommentTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"TGCommentTableViewCell" forIndexPath:indexPath];
	
	TGComment *comment = ((TGComment *)self.comments[indexPath.row]);
	
	cell.body.text = comment.body;
	cell.score.text = [NSString stringWithFormat:@"%lu points", (unsigned long) comment.score];
	cell.author.text = comment.author;
	
    return cell;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
