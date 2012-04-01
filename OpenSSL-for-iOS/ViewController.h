//
//  ViewController.h
//  OpenSSL-for-iOS
//
//  Created by Felix Schulze on 04.12.2010.
//  Updated by Schulze Felix on 01.04.12.
//  Copyright (c) 2012 Felix Schulze . All rights reserved.
//  Web: http://www.felixschulze.de
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (nonatomic, strong) IBOutlet UITextField *textField;
@property (nonatomic, strong) IBOutlet UILabel *md5TextField;
@property (nonatomic, strong) IBOutlet UILabel *sha256TextField;

- (IBAction)showInfo;
- (IBAction)calculateMD5:(id)sender;
- (IBAction)calculateSHA256:(id)sender;

@end
