//
//  OnboardViewController.swift
//  Cardiologic
//
//  Created by Ben Zimring on 7/27/18.
//  Copyright © 2018 pulseApp. All rights reserved.
//

import UIKit
import SwiftyOnboard
import HealthKit

class OnboardViewController: UIViewController {

    @IBOutlet weak var onboardView: SwiftyOnboard!
    let hkm = HealthKitManager()
    var namePage: SwiftyOnboardPage?
    var birthdayPage: SwiftyOnboardPage?
    var heightWeightPage: SwiftyOnboardPage?
    var genderPage: SwiftyOnboardPage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if hkm.isHealthDataAvailable() {
            requestAuthorization()
        }
        onboardView.style = .light
        onboardView.delegate = self
        onboardView.dataSource = self
        onboardView.backgroundColor = .white
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func handleContinue(sender: UIButton) {
        let index = sender.tag
        let pages = [namePage, birthdayPage, heightWeightPage, genderPage]
        if index < 3 {
            onboardView.goToPage(index: index + 1, animated: true)
            //NotificationCenter.default.post(Notification.init(name: AppDelegate.kInfoIncompleteNotification))
        } else {
            NSLog("attempting to save...")
            var pageIndex = 0
            for page in pages {
                if !page!.saveInfo() {
                    NSLog("error in onboard page \(pageIndex)")
                    onboardView.goToPage(index: pageIndex, animated: true)
                    return
                }
                pageIndex += 1
            }
            NSLog("done with onboarding...")
            UserDefaults.standard.set(true, forKey: "hasLaunched")
            
            if let main = storyboard?.instantiateViewController(withIdentifier: "TabBarViewController") {
                main.modalTransitionStyle = .crossDissolve
                present(main, animated: true, completion: nil)
            }
        }
        
    }

}

extension OnboardViewController: SwiftyOnboardDelegate, SwiftyOnboardDataSource {
    func swiftyOnboardNumberOfPages(_ swiftyOnboard: SwiftyOnboard) -> Int {
        return 4
    }
    
    func swiftyOnboardPageForIndex(_ swiftyOnboard: SwiftyOnboard, index: Int) -> SwiftyOnboardPage? {
        switch index {
        case 0:
            print("idx 0")
            let view = NamePage.instanceFromNib() as? NamePage
            namePage = view
            return view
        case 1:
            print("idx 1")
            let view = BirthdayPage.instanceFromNib() as? BirthdayPage
            view?.titleLabel.text = "Enter your"
            view?.image.image = UIImage(named: "birthday_large")
            view?.subTitleLabel.text = "birthday"
            birthdayPage = view
            return view
        case 2:
            print("idx 2")
            let view = HeightWeightPage.instanceFromNib() as? HeightWeightPage
            heightWeightPage = view
            return view
        default:
            print("idx 3")
            let view = GenderPage.instanceFromNib() as? GenderPage
            genderPage = view
            return view
        }
    }
    
    func swiftyOnboardViewForOverlay(_ swiftyOnboard: SwiftyOnboard) -> SwiftyOnboardOverlay? {
        let overlay = CustomOverlay.instanceFromNib() as? CustomOverlay
        overlay?.buttonContinue.addTarget(self, action: #selector(handleContinue), for: .touchUpInside)
        return overlay
    }
    
    func swiftyOnboardOverlayForPosition(_ swiftyOnboard: SwiftyOnboard, overlay: SwiftyOnboardOverlay, for position: Double) {
        let overlay = overlay as! CustomOverlay
        let currentPage = round(position)
        overlay.contentControl.currentPage = Int(currentPage)
        overlay.buttonContinue.tag = Int(position)

        if (0...2).contains(currentPage)  {
            overlay.buttonContinue.setTitle("Next", for: .normal)
        } else {
            overlay.buttonContinue.setTitle("Let's go!", for: .normal)
        }
    }
}

extension OnboardViewController {
    /* HealthKit auth */
    func requestAuthorization() {
        let readingTypes:Set<HKObjectType> = [.heartRateType,
                                              .restingHeartRateType,
                                              .workoutType(),
                                              .stepsType,
                                              .variabilityType,
                                              .genderType,
                                              .weightType,
                                              .heightType,
                                              .dateOfBirthType]
        
        // auth request
        hkm.requestAuthorization(readingTypes: readingTypes, writingTypes: nil) {
            print("auth success")
            DispatchQueue.main.async {
                self.birthdayPage?.fillIn()
                self.heightWeightPage?.fillIn()
                self.genderPage?.fillIn()
            }
        }
    }
}
