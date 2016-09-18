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
        let message = "OpenSSL-Version: \(OPENSSL_VERSION_TEXT)\nLicense: See include/LICENSE\n\nCopyright 2010-2016 by Felix Schulze\n http://www.felixschulze.de"
        let alertController = UIAlertController(title: "OpenSSL-for-iOS", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "OpenSSL-for-iOS"
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(ViewController.showInfo), for: .touchDown)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
        
        self.textField.addTarget(self, action: #selector(ViewController.textFieldDidChange), for: .editingChanged)
        self.calculateHash()
    }
    
    func textFieldDidChange() {
        self.calculateHash()
    }

    func calculateHash() {
        if textField.text!.characters.count > 0 {
            md5Label.text = FSOpenSSL.md5(from: textField.text)
            sh256Label.text = FSOpenSSL.sha256(from: textField.text)
        }
        else {
            md5Label.text = nil
            sh256Label.text = nil
        }
    }
    
}
