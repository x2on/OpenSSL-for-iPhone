//
//  ViewController.swift
//  OpenSSL-for-iOS
//
//  Created by Felix Schulze on 04.12.2010.
//  Updated by Felix Schulze on 17.11.2015.
//  Copyright © 2015 Felix Schulze. All rights reserved.
//  Web: http://www.felixschulze.de
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var textField: UITextField!
    @IBOutlet var md5Label: UILabel!
    @IBOutlet var sh256Label: UILabel!
    
    @IBAction
    func showInfo() {
        let message = "OpenSSL-Version: \(OPENSSL_VERSION_TEXT)\nLicense: See include/LICENSE\n\nCopyright 2010-2015 by Felix Schulze\n http://www.felixschulze.de"
        let alertController = UIAlertController(title: "OpenSSL-for-iOS", message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "OpenSSL-for-iOS"
        let infoButton = UIButton(type: .InfoLight)
        infoButton.addTarget(self, action: "showInfo", forControlEvents: .TouchDown)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
        
        self.textField.addTarget(self, action: "textFieldDidChange", forControlEvents: .EditingChanged)
        self.calculateHash()
    }
    
    func textFieldDidChange() {
        self.calculateHash()
    }

    func calculateHash() {
        if textField.text!.characters.count > 0 {
            md5Label.text = FSOpenSSL.md5FromString(textField.text)
            sh256Label.text = FSOpenSSL.sha256FromString(textField.text)
        }
        else {
            md5Label.text = nil
            sh256Label.text = nil
        }
    }
    
}
