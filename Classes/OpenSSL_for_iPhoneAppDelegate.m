//
//  OpenSSL_for_iPhoneAppDelegate.m
//  OpenSSL-for-iPhone
//
//  Created by Felix Schulze on 04.12.2010.
//  Copyright Felix Schulze 2010. All rights reserved.
//

#import "OpenSSL_for_iPhoneAppDelegate.h"
#include <Openssl/md5.h>

@implementation OpenSSL_for_iPhoneAppDelegate

@synthesize window, textField, md5TextField;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {   
	[window makeKeyAndVisible];
	return YES;
}

- (IBAction)calculateMD5:(id)sender
{
	/** Calculate MD5*/
	NSString *string =  textField.text;
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
	md5TextField.text = outStrg;
}

- (IBAction)showInfo {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OpenSSL-for-iOS" message:@"OpenSSL-Version: 1.0.0c\nLicense: See include/LICENSE\n\nCopyright 2010 by Felix Schulze\n http://www.x2on.de" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
	
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
