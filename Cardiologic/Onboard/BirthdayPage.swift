//
//  CustomPage.swift
//

import UIKit
import SwiftyOnboard

class BirthdayPage: SwiftyOnboardPage {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var monthTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var yearTextField: UITextField!
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "BirthdayPage", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // keyboard UI adjustment observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // textfield observers
        monthTextField.addTarget(self, action: #selector(monthTextFieldDidChange), for: .editingChanged)
        dateTextField.addTarget(self, action: #selector(dateTextFieldDidChange), for: .editingChanged)
        yearTextField.addTarget(self, action: #selector(yearTextFieldDidChange), for: .editingChanged)
    
        dateTextField.isEnabled = false
        yearTextField.isEnabled = false
        
        addKeyboardDoneButton()
    }
    
    override func saveInfo() -> Bool {
        NSLog("saving user birthday info")
        guard let month = monthTextField.text else { return false }
        guard let day = dateTextField.text else { return false }
        guard let year = yearTextField.text else { return false }
        var birthDict = [String: Int]()
        birthDict["month"] = Int(month)
        birthDict["day"] = Int(day)
        birthDict["year"] = Int(year)
        if isValidDate(date: "\(year)-\(month)-\(day)") {
            UserDefaults.standard.set(birthDict, forKey: "userBirthDict")
            return true
        }
        return false
    }
    
    func isValidDate(date: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        guard let _ = dateFormatter.date(from: date) else {
            print("bad")
            return false
        }
        return true
    }
    
    @objc func doneButton() {
        dateTextField.resignFirstResponder()
        monthTextField.resignFirstResponder()
        yearTextField.resignFirstResponder()
    }

}

// MARK: - textfield delegation
extension BirthdayPage: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("didBeginEditing")
        NotificationCenter.default.post(Notification.init(name: AppDelegate.kHideLogoNotification))
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("didEndEditing")
    }
    
    func addKeyboardDoneButton() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 20))
        doneToolbar.barStyle = .blackOpaque
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(doneButton))
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        self.monthTextField.inputAccessoryView = doneToolbar
        self.dateTextField.inputAccessoryView = doneToolbar
        self.yearTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func monthTextFieldDidChange() {
        guard let text = monthTextField.text else { return }
        if text.count > 0 {
            if let month = Int(text) {
                if (1...12).contains(month) { dateTextField.isEnabled = true}
                if text.count == 2 { dateTextField.becomeFirstResponder() }
            }
        }
    }
    
    @objc func dateTextFieldDidChange() {
        guard let text = dateTextField.text else { return }
        if text.count > 0 {
            if let date = Int(dateTextField.text!) {
                if (1...31).contains(date) { yearTextField.isEnabled = true }
                if text.count == 2 { yearTextField.becomeFirstResponder() }
            }
        }
    }
    
    @objc func yearTextFieldDidChange() {
        if yearTextField.text?.count == 4 {
            if let year = Int(yearTextField.text!) {
                if (1900...2018).contains(year) {
                    yearTextField.resignFirstResponder()
                    NotificationCenter.default.post(Notification.init(name: AppDelegate.kInfoCompleteNotification))
                }
            }
        } else {
            NotificationCenter.default.post(Notification.init(name: AppDelegate.kInfoIncompleteNotification))
        }
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.frame.origin.y == 0 {
                self.frame.origin.y -= keyboardSize.height/2
            }
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        if let _ = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.frame.origin.y != 0 {
                self.frame.origin.y = 0
            }
            NotificationCenter.default.post(Notification.init(name: AppDelegate.kShowLogoNotification))
        }
    }
}
