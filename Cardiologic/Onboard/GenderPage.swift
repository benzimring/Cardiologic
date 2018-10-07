//
//  CustomPage.swift
//

import UIKit
import SwiftyOnboard

class GenderPage: SwiftyOnboardPage {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    
    @IBOutlet weak var maleButton: UIButton!
    @IBOutlet weak var femaleButton: UIButton!
    
    enum Gender {
        case male
        case female
        case none
    }
    
    var selectedGender: Gender = .none
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "GenderPage", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    override func awakeFromNib() {
        maleButton.setImage(UIImage(named: "male_filled")!, for: .highlighted)
        femaleButton.setImage(UIImage(named: "female_filled")!, for: .highlighted)
    }

    @IBAction func didTouchMaleButton(_ sender: Any) {
        print("didTouchMaleButton")
        
        // unselect female button
        if selectedGender == .female {
            DispatchQueue.main.async {
                UIView.transition(with: self.femaleButton.imageView!, duration: 0.2, options: .transitionCrossDissolve, animations: {
                    let newImage = UIImage(named: "female_unfilled")!
                    self.femaleButton.imageView?.image = newImage
                })
            }
        }
        
        // select male button
        DispatchQueue.main.async {
            UIView.transition(with: self.maleButton.imageView!, duration: 0.2, options: .transitionCrossDissolve, animations: {
                let newImage = UIImage(named: "male_filled")!
                self.maleButton.imageView?.image = newImage
            })
        }
        selectedGender = .male
        maleButton.isMultipleTouchEnabled = false
        femaleButton.isMultipleTouchEnabled = true
        NotificationCenter.default.post(Notification.init(name: AppDelegate.kInfoCompleteNotification))
    }
    
    @IBAction func didTouchFemaleButton(_ sender: Any) {
        print("didTouchFemaleButton")
        
        // unselect male button
        if selectedGender == .male {
            DispatchQueue.main.async {
                UIView.transition(with: self.maleButton.imageView!, duration: 0.2, options: .transitionCrossDissolve, animations: {
                    let newImage = UIImage(named: "male_unfilled")!
                    self.maleButton.imageView?.image = newImage
                })
            }
        }
        
        // select female button
        DispatchQueue.main.async {
            UIView.transition(with: self.femaleButton.imageView!, duration: 0.2, options: .transitionCrossDissolve, animations: {
                let newImage = UIImage(named: "female_filled")!
                self.femaleButton.imageView?.image = newImage
            })
        }
        selectedGender = .female
        femaleButton.isMultipleTouchEnabled = false
        maleButton.isMultipleTouchEnabled = true
        NotificationCenter.default.post(Notification.init(name: AppDelegate.kInfoCompleteNotification))
    }
    
    override func saveInfo() -> Bool {
        switch selectedGender {
        case .male:
            UserDefaults.standard.set("Male", forKey: "userGender")
        case .female:
            UserDefaults.standard.set("Female", forKey: "userGender")
        default:
            return false
        }
        return true
    }
    
}
