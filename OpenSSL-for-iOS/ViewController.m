//
//  ViewController.m
//  OpenSSL-for-iOS
//
//  Created by Felix Schulze on 04.12.2010.
//  Updated by Schulze Felix on 01.04.12.
//  Copyright (c) 2012 Felix Schulze . All rights reserved.
//  Web: http://www.felixschulze.de
//

#import "ViewController.h"
#import "FSOpenSSL.h"
#include <openssl/opensslv.h>

@implementation ViewController

@synthesize textField;
@synthesize md5TextField;
@synthesize sha256TextField;

#pragma mark -
#pragma mark OpenSSL

- (IBAction)calculateMD5:(id)sender
{
	md5TextField.text = [FSOpenSSL md5FromString:textField.text];
	//Hide Keyboard after calculation
	[textField resignFirstResponder];
}

- (IBAction)calculateSHA256:(id)sender 
{
	sha256TextField.text = [FSOpenSSL sha256FromString:textField.text];
	//Hide Keyboard after calculation
	[textField resignFirstResponder];
}

- (IBAction)showInfo 
{	
    NSString *message = [NSString stringWithFormat:@"OpenSSL-Version: %@\nLicense: See include/LICENSE\n\nCopyright 2010-2013 by Felix Schulze\n http://www.felixschulze.de", @OPENSSL_VERSION_TEXT];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OpenSSL-for-iOS" message:message delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];	
	[alert show];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{   
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
