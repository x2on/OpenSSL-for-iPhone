//
//  AppDelegate.m
//  OpenSSL-for-iOS
//
//  Created by Felix Schulze on 04.12.2010.
//  Updated by Schulze Felix on 01.04.12.
//  Copyright (c) 2012 Felix Schulze . All rights reserved.
//  Web: http://www.felixschulze.de
//

#import "AppDelegate.h"
#import "ViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    UIViewController *viewController = [[ViewController alloc] init];
#if TARGET_OS_TV
    self.window.rootViewController = viewController;
#else
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navigationController.navigationBar.translucent = NO;
    self.window.rootViewController = navigationController;
#endif
    [self.window makeKeyAndVisible];
    return YES;
}


@end
