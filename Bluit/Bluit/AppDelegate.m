//
//  AppDelegate.m
//  redditPad
//
//  Created by Tom Graham on 03/03/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "AppDelegate.h"

#import "ThemeManager.h"
#import "TGRedditClient.h"

#import "FrontPageViewController.h"
#import "TGSubredditListViewController.h"

@interface AppDelegate () <UISplitViewControllerDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeAppearance) name:kThemeDidChangeNotification object:nil];
	[self themeAppearance];
	
	UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
	UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
	navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
	splitViewController.delegate = self;
	
	FrontPageViewController *listingVC = (FrontPageViewController *) [[splitViewController.viewControllers lastObject] topViewController];
	TGSubredditListViewController *subredditVC = (TGSubredditListViewController *) [[splitViewController.viewControllers objectAtIndex:0] topViewController];
	subredditVC.delegate = listingVC;
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(BOOL) application:(UIApplication *)application
			openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
		 annotation:(id)annotation
{
	NSLog(@"AppDelegate passed URL: %@", [url absoluteString]);
	
	if ([url.scheme isEqualToString: [[TGRedditClient sharedClient] uriScheme]])
	{
		// check our `host` value to see what screen to display
		if ([url.host isEqualToString: @"showSubreddit"])
		{
			// break down NSURL, get subreddit `name` queryItem
			NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url
														resolvingAgainstBaseURL:NO];
			NSArray *queryItems = urlComponents.queryItems;
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=name"];
			NSURLQueryItem *queryItem = [[queryItems filteredArrayUsingPredicate:predicate] firstObject];
			NSString *subreddit = [NSString stringWithFormat:@"/r/%@/", queryItem.value];
			
			// make root listingVC loadSubreddit — specific to splitVC implementation
			UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
			FrontPageViewController *listingVC = (FrontPageViewController *) [[splitViewController.viewControllers lastObject] topViewController];
			[listingVC didSelectSubreddit:subreddit];
		}
		else
		{
			NSLog(@"An unknown action was passed.");
		}
	}
	
	return NO;
}

#pragma mark - Customisation

- (void) themeAppearance
{
	[[UIApplication sharedApplication] setStatusBarStyle:[ThemeManager statusBarStyle] animated:YES];
	
	self.window.tintColor = [ThemeManager colorForKey:kTGThemeTintColor];
	
	UIView *selectedTableViewBG = [UIView new];
	[selectedTableViewBG setBackgroundColor:[ThemeManager colorForKey:kTGThemeFadedBackgroundColor]];
	[[UITableViewCell appearance] setSelectedBackgroundView: selectedTableViewBG];
	[[UITableViewCell appearance] setBackgroundColor:[ThemeManager colorForKey:kTGThemeContentBackgroundColor]];
	[[UITableView appearance] setBackgroundColor:[ThemeManager colorForKey:kTGThemeBackgroundColor]];
	[[UITableView appearance] setSeparatorColor: [ThemeManager colorForKey:kTGThemeSeparatorColor]];
	
	[[UIScrollView appearance] setIndicatorStyle:(UIScrollViewIndicatorStyle) [ThemeManager scrollViewIndicatorStyle]];
	
	[[UIWebView appearance] setBackgroundColor:[ThemeManager colorForKey:kTGThemeBackgroundColor]];
	
	[[UINavigationBar appearance] setBarStyle:[ThemeManager uiBarStyle]];
	[[UINavigationBar appearance] setBarTintColor:[ThemeManager colorForKey:kTGThemeContentBackgroundColor]];
	NSDictionary *attributes = @{NSForegroundColorAttributeName:	[ThemeManager colorForKey:kTGThemeTextColor],
								 NSFontAttributeName:			[UIFont fontWithName:@"AvenirNext-DemiBold" size:17.0f]};
	[[UINavigationBar appearance] setTitleTextAttributes:attributes];
	[[UIToolbar appearance] setBarTintColor:[ThemeManager colorForKey:kTGThemeContentBackgroundColor]];
	[[UITabBar appearance] setBarTintColor:[ThemeManager colorForKey:kTGThemeContentBackgroundColor]];
	
	[[UILabel appearance] setTextColor:[ThemeManager colorForKey:kTGThemeTextColor]];
	
	[[UITextField appearance] setFont:[UIFont fontWithName:@"AvenirNext-Medium" size:15.0f]];
	[[UITextField appearance] setTextColor:[ThemeManager colorForKey:kTGThemeTextColor]];
	
	attributes = @{NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Medium" size:14.0f]};
	[[UISegmentedControl appearance] setTitleTextAttributes:attributes forState:UIControlStateNormal];
	[[UISegmentedControl appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[ThemeManager colorForKey:kTGThemeContentBackgroundColor]} forState:UIControlStateSelected];
}

@end
