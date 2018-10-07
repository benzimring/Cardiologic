//
//  CustomPage.swift
//

import UIKit
import SwiftyOnboard

class NamePage: SwiftyOnboardPage {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var subTitleLabel: UILabel!
    
    @IBOutlet weak var nameTextField: UITextField!

    class func instanceFromNib() -> UIView {
        return UINib(nibName: "NamePage", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    override func awakeFromNib() {
        nameTextField.addTarget(self, action: #selector(nameTextFieldDidChange), for: .editingChanged)
    }
    
    @objc func nameTextFieldDidChange() {
        guard let text = nameTextField.text else { return }
        if text.count > 0 {
            NotificationCenter.default.post(Notification.init(name: AppDelegate.kInfoCompleteNotification))
        } else {
            NotificationCenter.default.post(Notification.init(name: AppDelegate.kInfoIncompleteNotification))
        }
    }
    
    override func saveInfo() -> Bool {
        guard let name = nameTextField.text else { return false }
        if name.isEmpty { return false }
        UserDefaults.standard.set(name, forKey: "userName")
        return true
    }

}

extension NamePage: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nameTextField.resignFirstResponder()
        return true
    }
}
