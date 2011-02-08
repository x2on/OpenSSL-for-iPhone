//
//  OpenSSL_for_iOSAppDelegate.m
//  OpenSSL-for-iOS
//
//  Created by Felix Schulze on 04.12.2010.
//  Copyright Felix Schulze 2010. All rights reserved.
//

#import "OpenSSL_for_iOSAppDelegate.h"
#include <Openssl/md5.h>
#include <Openssl/sha.h>

@implementation OpenSSL_for_iOSAppDelegate

@synthesize window, textField, md5TextField, sha256TextField;


#pragma mark -
#pragma mark OpenSSL

- (IBAction)calculateMD5:(id)sender
{
	/** Calculate MD5*/
	NSString *string =  textField.text;
    unsigned char *inStrg = (unsigned char*)[[string dataUsingEncoding:NSASCIIStringEncoding] bytes];
    unsigned long lngth = [string length];
	unsigned char result[MD5_DIGEST_LENGTH];
	NSMutableString *outStrg = [NSMutableString string];
	
    MD5(inStrg, lngth, result);
	
    unsigned int i;
    for (i = 0; i < MD5_DIGEST_LENGTH; i++)
    {
        [outStrg appendFormat:@"%02x", result[i]];
    }
	md5TextField.text = outStrg;
	
	//Hide Keyboard after calculation
	[textField resignFirstResponder];
}

- (IBAction)calculateSHA256:(id)sender {
	
	/* Calculate SHA256 */
	NSString *string =  textField.text;
    unsigned char *inStrg = (unsigned char*)[[string dataUsingEncoding:NSASCIIStringEncoding] bytes];
	unsigned long lngth = [string length];
	unsigned char result[SHA256_DIGEST_LENGTH];
    NSMutableString *outStrg = [NSMutableString string];
	
    SHA256_CTX sha256;
    SHA256_Init(&sha256);
    SHA256_Update(&sha256, inStrg, lngth);
    SHA256_Final(result, &sha256);
	
    unsigned int i;
    for(i = 0; i < SHA256_DIGEST_LENGTH; i++)
    {
        [outStrg appendFormat:@"%02x", result[i]];
    }
	sha256TextField.text = outStrg;
	
	//Hide Keyboard after calculation
	[textField resignFirstResponder];
}

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {   
	[window makeKeyAndVisible];
	return YES;
}

- (IBAction)showInfo {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OpenSSL-for-iOS" message:@"OpenSSL-Version: 1.0.0d\nLicense: See include/LICENSE\n\nCopyright 2010-2011 by Felix Schulze\n http://www.x2on.de" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
	
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