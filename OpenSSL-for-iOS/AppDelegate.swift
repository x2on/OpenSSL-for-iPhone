//
//  AppDelegate.swift
//  OpenSSL-for-iOS
//
//  Created by Felix Schulze on 04.12.2010.
//  Updated by Felix Schulze on 17.11.2015.
//  Copyright © 2015 Felix Schulze. All rights reserved.
//  Web: http://www.felixschulze.de
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        #if os(tvOS)
            self.window?.rootViewController = ViewController(nibName: "ViewController~tv", bundle:  nil)
        #else
            let navigationController = UINavigationController(rootViewController: ViewController())
            navigationController.navigationBar.translucent = false
            self.window?.rootViewController = navigationController
        #endif
        
        self.window?.makeKeyAndVisible()
        return true
    }

}

