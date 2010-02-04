//
//  OpenSSL_1AppDelegate.m
//  OpenSSL-1
//
//  Created by Felix Schulze on 01.02.2010.
//  Copyright Felix Schulze 2010. All rights reserved.
//

#import "OpenSSL_1AppDelegate.h"
#include <Openssl/md5.h>

@implementation OpenSSL_1AppDelegate

@synthesize window;

UITextField *textView;
UILabel *label;

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
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
	

- (void)dealloc {
    [window release];
    [super dealloc];
}


@end
