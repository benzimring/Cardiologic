//
//  CustomPage.swift
//

import UIKit
import SwiftyOnboard
import AORangeSlider
import Lottie

class HeightWeightPage: SwiftyOnboardPage {
    let hkm = HealthKitManager()
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var subTitleLabel: UILabel!
    
    // textfields

    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var weightTextField: UITextField!
    
    @IBOutlet weak var heightSlider: AORangeSlider!
    @IBOutlet weak var slideAnimation: LOTAnimationView!
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "HeightWeightPage", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        weightTextField.addTarget(self, action: #selector(weightTextChanged), for: .editingChanged)
        addWeightDoneButton()
    }
    
    override func fillIn() {
        // fetch weight
        hkm.userWeight() { weight in
            if weight != -1 {
                DispatchQueue.main.async {
                    self.weightTextField.text = String(weight)
                }
            }
        }
        
        // fetch height
        hkm.userHeight() { height in
            DispatchQueue.main.async {
                if height == -1 {
                    self.initHeightSlider(70)
                } else {
                    self.initHeightSlider(height)
                }
            }
        }
    }

    
    /* adds "Done" button to weight input */
    func addWeightDoneButton() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 20))
        doneToolbar.barStyle = .blackOpaque
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(doneButton))
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        self.weightTextField.inputAccessoryView = doneToolbar
    }
    
    func initHeightSlider(_ value: Int) {
        heightSlider.minimumValue = 0.5
        heightSlider.maximumValue = 0.85
        heightSlider.highValue = Double(value)/100
        heightSlider.highHandleImageNormal = #imageLiteral(resourceName: "height_right")
        
        heightSlider.trackBackgroundImage = #imageLiteral(resourceName: "hollowProgress").resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5))
        heightSlider.trackImage = #imageLiteral(resourceName: "solidProgress").resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5))
        heightSlider.isLowHandleHidden = true
        heightSlider.stepValue = 0.01
        heightSlider.stepValueContinuously = true
        
        heightSlider.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        heightSlider.valuesChangedHandler = {
            let inches = Int(self.heightSlider.highValue*100)
            let feet = inches/12
            let r = inches%12
            self.heightLabel.text = "\(feet)' \(r)\""
            if inches != value {
                self.slideAnimation.stop()
                self.slideAnimation.alpha = 0
            }
        }
        
        slideAnimation.setAnimation(named: "scroll_animation")
        slideAnimation.loopAnimation = true
        slideAnimation.play()
    }
    
    override func saveInfo() -> Bool {
        guard let weight = weightTextField.text else { return false }
        if weight.isEmpty { return false }
        let height = heightSlider.highValue*100
        UserDefaults.standard.set(Int(weight), forKey: "userWeight")
        UserDefaults.standard.set(Int(height), forKey: "userHeight")
        return true
    }
    
    @objc func doneButton() {
        weightTextField.resignFirstResponder()
    }
    
    @objc func weightTextChanged() {
        if weightTextField.text?.count == 3 {
            weightTextField.resignFirstResponder()
        }
    }
    
}
