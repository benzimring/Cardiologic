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
    
}
