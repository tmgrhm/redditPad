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

#pragma mark - Initialisation

- (void) themeAppearance
{
	[[UIApplication sharedApplication] setStatusBarStyle:[ThemeManager statusBarStyle]
												animated:UIStatusBarAnimationFade]; // TODO
	
	UIView *selectedTableViewBG = [UIView new];
	[selectedTableViewBG setBackgroundColor:[ThemeManager backgroundColor]];
	[[UITableViewCell appearance] setSelectedBackgroundView: selectedTableViewBG];
	[[UITableViewCell appearance] setBackgroundColor:[ThemeManager contentBackgroundColor]];
	[[UITableView appearance] setBackgroundColor:[ThemeManager backgroundColor]];
	[[UITableView appearance] setSeparatorColor: [ThemeManager separatorColor]];
	
//	[[UIScrollView appearance] setBackgroundColor:[ThemeManager backgroundColor]];
	[[UIWebView appearance] setBackgroundColor:[ThemeManager backgroundColor]];
	
	[[UINavigationBar appearance] setBarStyle:[ThemeManager uiBarStyle]];
	[[UINavigationBar appearance] setBarTintColor:[ThemeManager contentBackgroundColor]];
	[[UINavigationBar appearance] setTintColor:[ThemeManager tintColor]];
	NSDictionary *attributes = @{NSForegroundColorAttributeName:	[ThemeManager textColor],
								 NSFontAttributeName:			[UIFont fontWithName:@"AvenirNext-DemiBold" size:17.0f]};
	[[UINavigationBar appearance] setTitleTextAttributes:attributes];
	[[UIToolbar appearance] setBarTintColor:[ThemeManager contentBackgroundColor]];
	[[UIToolbar appearance] setTintColor:[ThemeManager tintColor]];
	[[UITabBar appearance] setBarTintColor:[ThemeManager contentBackgroundColor]];
	[[UITabBar appearance] setTintColor:[ThemeManager tintColor]];
	
	[[UILabel appearance] setTextColor:[ThemeManager textColor]];
	
	[[UITextField appearance] setFont:[UIFont fontWithName:@"AvenirNext-Medium" size:15.0f]];
	[[UITextField appearance] setTintColor:[ThemeManager tintColor]];
	[[UITextField appearance] setTextColor:[ThemeManager textColor]];
	
	[[UITextView appearance] setTintColor:[ThemeManager tintColor]];

	[[UIButton appearance] setTitleColor:[ThemeManager tintColor] forState:UIControlStateNormal];
	
	[[UISegmentedControl appearance] setTintColor:[ThemeManager tintColor]];
	attributes = @{NSFontAttributeName:				[UIFont fontWithName:@"AvenirNext-Medium" size:14.0f],
				   NSForegroundColorAttributeName:	[ThemeManager tintColor]};
	[[UISegmentedControl appearance] setTitleTextAttributes:attributes forState:UIControlStateNormal];
	[[UISegmentedControl appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[ThemeManager contentBackgroundColor]} forState:UIControlStateSelected];
}

@end
