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
#include <openssl/md5.h>
#include <openssl/sha.h>
#include <openssl/opensslv.h>

@implementation ViewController

@synthesize textField;
@synthesize md5TextField;
@synthesize sha256TextField;

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

- (IBAction)calculateSHA256:(id)sender 
{	
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

- (IBAction)showInfo 
{	
    NSString *version = [NSString stringWithCString:OPENSSL_VERSION_TEXT encoding:NSUTF8StringEncoding];
    NSString *message = [NSString stringWithFormat:@"OpenSSL-Version: %@\nLicense: See include/LICENSE\n\nCopyright 2010-2012 by Felix Schulze\n http://www.x2on.de", version];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OpenSSL-for-iOS" message:message delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];	
	[alert show];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{   
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
