//
//  CustomOverlay.swift
//  SwiftyOnboardExample
//
//  Created by Jay on 3/27/17.
//  Copyright © 2017 Juan Pablo Fernandez. All rights reserved.
//

import UIKit
import SwiftyOnboard

class CustomOverlay: SwiftyOnboardOverlay {
    
    @IBOutlet weak var buttonContinue: UIButton!
    @IBOutlet weak var contentControl: UIPageControl!
    @IBOutlet weak var appLogo: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        

        NotificationCenter.default.addObserver(self, selector: #selector(hideLogo), name: AppDelegate.kHideLogoNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showLogo), name: AppDelegate.kShowLogoNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enableContinue), name: AppDelegate.kInfoCompleteNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(disableContinue), name: AppDelegate.kInfoIncompleteNotification, object: nil)
        
        buttonContinue.alpha = 0
        buttonContinue.isMultipleTouchEnabled = false
    }
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "CustomOverlay", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    @objc func hideLogo() {
        UIView.animate(withDuration: 0.2) {
            self.appLogo.alpha = 0
        }
    }
    
    @objc func showLogo() {
        UIView.animate(withDuration: 0.2) {
            self.appLogo.alpha = 1
        }
    }
    
    @objc func enableContinue() {
        print("enableContinue")
        if !self.buttonContinue.isMultipleTouchEnabled {
            print("enabling Next button multiple touch")
            self.buttonContinue.isMultipleTouchEnabled = true
        }
        UIView.animate(withDuration: 0.2) {
            self.buttonContinue.alpha = 1
        }
    }
    
    @objc func disableContinue() {
        print("disableContinue")
        //self.buttonContinue.isMultipleTouchEnabled = false
        UIView.animate(withDuration: 0.2) {
            self.buttonContinue.alpha = 0
        }
    }
    
}
