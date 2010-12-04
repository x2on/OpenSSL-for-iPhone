//
//  OpenSSL_for_iOSAppDelegate.h
//  OpenSSL-for-iOS
//
//  Created by Felix Schulze on 01.02.2010.
//  Copyright Felix Schulze 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OpenSSL_for_iOSAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	
	IBOutlet UITextField *textField;
	IBOutlet UILabel *md5TextField;
	IBOutlet UILabel *sha256TextField;
	
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITextField *textField;
@property (nonatomic, retain) IBOutlet UILabel *md5TextField;
@property (nonatomic, retain) IBOutlet UILabel *sha256TextField;


- (IBAction)showInfo;
- (IBAction)calculateMD5:(id)sender;
- (IBAction)calculateSHA256:(id)sender;
@end

