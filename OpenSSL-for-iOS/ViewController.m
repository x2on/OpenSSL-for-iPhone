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

- (instancetype)init
{
    NSString *nibName = @"ViewController";
#if TARGET_OS_TV
    nibName = @"ViewController~tv";
#endif
    self = [super initWithNibName:nibName bundle:nil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    self.title = @"OpenSSL-for-iOS";
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];

    [_textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    [self calculateHash];
    
    [super viewDidLoad];
}

- (IBAction)textFieldDidChange:(id)sender
{
    [self calculateHash];
}

- (void)calculateHash
{
    if (_textField.text.length > 0)
    {
        _md5TextField.text = [FSOpenSSL md5FromString:_textField.text];
        _sha256TextField.text = [FSOpenSSL sha256FromString:_textField.text];
    }
    else
    {
        _md5TextField.text = nil;
        _sha256TextField.text = nil;
    }
}

- (IBAction)showInfo
{	
    NSString *message = [NSString stringWithFormat:@"OpenSSL-Version: %@\nLicense: See include/LICENSE\n\nCopyright 2010-2015 by Felix Schulze\n http://www.felixschulze.de", @OPENSSL_VERSION_TEXT];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"OpenSSL-for-iOS" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
