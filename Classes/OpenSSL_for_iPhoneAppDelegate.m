//
//  OpenSSL_for_iPhoneAppDelegate.m
//  OpenSSL-for-iPhone
//
//  Created by Felix Schulze on 30.06.2010.
//  Copyright Felix Schulze 2010. All rights reserved.
//

#import "OpenSSL_for_iPhoneAppDelegate.h"
#include <Openssl/md5.h>

@implementation OpenSSL_for_iPhoneAppDelegate

@synthesize window;

UITextField *textView;
UILabel *label;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:
                               CGRectMake( 0.0f, 20.0f, window.frame.size.width, 48.0f)];
    [navBar setBarStyle: 0];
	
	UINavigationItem *title = [[UINavigationItem alloc] initWithTitle:@"OpenSSL-Test"];
    [navBar pushNavigationItem:title animated:true];
	
	UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[infoButton addTarget:self action:@selector(infoView) forControlEvents:UIControlEventTouchUpInside];
	
	UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
	title.rightBarButtonItem = buttonItem;
	[buttonItem release];
	
	textView = [[UITextView alloc] initWithFrame: CGRectMake(5, 100, 310, 50)];
	textView.backgroundColor = [UIColor lightGrayColor]; 
	[textView setText:@"Testing text"];
	
	label = [[UILabel alloc] initWithFrame:CGRectMake(20, 200, 320.0f, 100)];
	label.font = [UIFont fontWithName:@"Courier New" size: 10.0];
	[label setText:@"MD5-Hash"];
	
	UIButton *button = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];	button.frame = CGRectMake(100, 150, 100, 50);
	[button setTitle:@"Calc MD5" forState:UIControlStateNormal];
	button.backgroundColor = [UIColor clearColor];
	[button addTarget:self action:@selector(action:) forControlEvents:UIControlEventTouchUpInside];
	button.adjustsImageWhenHighlighted = YES;
	
	
    [window addSubview:textView];
    [window addSubview:navBar];
	[window addSubview:button];
	[window addSubview:label];
    [window makeKeyAndVisible];
	
	
    [title release];
    [navBar release];
	[textView release];
	[label release];
	[button release];
	
	return YES;
}

- (void)action:(id)sender
{
	
	/** Calculate MD5*/
	NSString *string =  textView.text;
	unsigned char result[16];
    unsigned char *inStrg = (unsigned char*)[[string dataUsingEncoding:NSASCIIStringEncoding] bytes];
    unsigned long lngth = [string length];
    MD5(inStrg, lngth, result);
    NSMutableString *outStrg = [NSMutableString string];
    unsigned int i;
    for (i = 0; i < 16; i++)
    {
        [outStrg appendFormat:@"%02x", result[i]];
    }
	[label setText:outStrg];
}

- (void) infoView
{
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OpenSSL-Test" message:@"Copyright 2010 by Felix Schulze\n http://www.x2on.de" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
	
	[alert show];
	[alert release];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    [window release];
    [super dealloc];
}


@end
