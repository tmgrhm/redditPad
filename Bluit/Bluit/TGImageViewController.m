//
//  TGImageViewController.m
//  redditPad
//
//  Created by Tom Graham on 27/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGImageViewController.h"
#import "ThemeManager.h"

#import <AFNetworking/UIImageView+AFNetworking.h>

@interface TGImageViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *fadeView;

@end

@implementation TGImageViewController

- (instancetype) initWithImage:(UIImage *)image
{
	if (self = [self init])
	{
		self.imageView.image = image;
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	[self themeAppearance];
	
	[self.scrollView addSubview:self.imageView];
	self.scrollView.minimumZoomScale = 0.5;
	self.scrollView.maximumZoomScale = 5.0;
	self.scrollView.delegate = self;
	
	[self loadImageFromURL:self.imageURL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)handleDismissTap:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void) themeAppearance
{
	self.fadeView.backgroundColor = [ThemeManager backgroundColor];
	self.fadeView.alpha = 0.5f;
}

-(UIImageView *)imageView
{
	if (!_imageView) _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
	return _imageView;
}


-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return self.imageView;
}

- (void)setImage:(UIImage *)image
{
	self.imageView.image = image;
	
	// update scrollView.contentSize to the size of the image
	self.scrollView.zoomScale = 1.0; // reset zoomScale for new image
	self.scrollView.contentSize = image.size;
	
	CGPoint midpoint = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
	self.imageView.frame = CGRectMake(midpoint.x - image.size.width / 2.0, midpoint.y - image.size.height / 2.0, image.size.width, image.size.height);
}

- (void)loadImageFromURL:(NSURL *)url
{
	__weak __typeof(self)weakSelf = self;
	[self.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:url]
						  placeholderImage:[UIImage imageNamed:@"Comments-Icon"]
								   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
	{
		[weakSelf setImage: image];
	}
								   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)
	{
		NSLog(@"Failure loading image :(");
	}];
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
