//
//  UIVC-Extension.swift
//  RentSpace
//
//  Created by Sean Williams on 01/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import NVActivityIndicatorView
import Foundation
import UIKit

extension UIViewController {
    
    //MARK: - Universal Alert Controller
    
    func showAlert(title: String, message: String?) {
        DispatchQueue.main.async {
            let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        }
    }

    
    //MARK: - Move view when keyboard appears on bottom text field
    
    // - Move screen up
    @objc func keyboardWillShow(_ notifictation: Notification) {
        view.frame.origin.y = -getKeyboardHeight(notifictation)
    }

    // - Move screen down
    @objc func keyboardWillHide(_ notification: Notification) {
        if view.frame.origin.y != 0 {
            view.frame.origin.y = 0
        }
    }
        
    // - Calculate keyboard height
    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return 0}
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        return keyboardViewEndFrame.height
    }

    // - Make view controller subscribe to keyboard notifications
    func subscribeToKeyboardNotificationsPostVC() {
        NotificationCenter.default.addObserver(self, selector: #selector(PostSpaceViewController.keyboardWillShowOnPostVC(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }

    // - Unsubscribe from keyboard notifications
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    //MARK: - Dismiss keyboard when view is tapped

    func dismissKeyboardOnViewTap() {
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        view.addGestureRecognizer(tap)
    }
    
    
    
    //MARK: - Format address for location labels from address data
    
    func formatAddress(for advert: Space) -> String {
        
        var location = ""
        let city = advert.city
        let subAdminArea = advert.subAdminArea
        let town = advert.town
        let state = advert.state
        
        if city == subAdminArea {
            location = "\(town), \(city)"
            if town == "" {
                location = "\(city)"
            }
        } else {
            location = "\(town), \(city), \(subAdminArea)"
            if town == "" {
                location = "\(city), \(subAdminArea)"
            }
        }
        
        if city == "" && town == "" {
            location = subAdminArea
            
            if subAdminArea == "" {
                location = state
            }
        }
        
        return location
    }
    
    
    //MARK: - Format price rates

    func priceRateFormatter(rate: String) -> String {
        switch rate {
        case "Hourly":
            return "P/H"
        case "Daily":
            return "P/D"
        case "Weekly":
            return "P/W"
        case "Monthly":
            return "P/M"
        case "Annually":
            return "P/Y"
        default:
            return "P/H"
        }
    }
    
    
    //MARK: - Write / Delete files on disk
    
    func writeImageFileToDisk(image: UIImage, name imageName: String, at position: Int, in imagesArray: inout [Image]) {
        let filePath = getDocumentsDirectory().appendingPathComponent(imageName)
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            try? imageData.write(to: filePath)
        }
        
        let savingImage = Image(imageName: imageName)
        imagesArray.insert(savingImage, at: position)
    }
    
    
    func deleteFileFromDisk(at URL: URL) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: URL)
        } catch let error as NSError {
            print(error.debugDescription)
        }
    }
    
    
    //MARK: - Get documents directory on device

    func getDocumentsDirectory() -> URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return path[0]
    }
    
    
    //MARK: - Show/Hide loading animations
    
    func showLoadingUI(_ loading: Bool, for activityView: NVActivityIndicatorView, label: UILabel, text: String) {
        if loading {
            label.text = text
            label.alpha = 0
            activityView.startAnimating()
            UIView.animate(withDuration: 7) {
                label.alpha = 1
            }
        } else {
            activityView.stopAnimating()
            label.alpha = 0
            label.isHidden = true
        }
    }
    
    //MARK: - Tintable category icon method
    
    func renderTemplateImage(imageName: String) -> UIImage? {
        if #available(iOS 13.0, *) {
            if let image = UIImage(systemName: imageName) {
                let templateImage = image.withRenderingMode(.alwaysTemplate)
                return templateImage
            }
        } else {
            if let image = UIImage(named: imageName) {
                let templateImage = image.withRenderingMode(.alwaysTemplate)
                return templateImage
            }
        }
        return nil
    }
    
    
    // MARK: - Validation Methods
    
    // Use regEx and NSPredicate to validate email address and password
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z.]{2,64}"
        
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func isValidPassword(_ password: String) -> Bool {
        let passwordRegEx = "^(?=.*[A-Z])(?=.*[0-9])(?=.*[a-z]).{6,}$"
        
        let passwordPred = NSPredicate(format: "SELF MATCHES %@", passwordRegEx)
        return passwordPred.evaluate(with: password)
    }
    
    func isValidDisplayName(_ displayName: String) -> Bool {
        return displayName.count > 2
    }
    
    func isTextViewEmpty(for textview: UITextView) -> Bool {
        guard let text = textview.text,
        
            !text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else { return true }
        
        return false
    }
    
    
    //MARK: - UI Helper Methods

    func addLeftPadding(for textfield: UITextField, placeholderText: String, placeholderColour: UIColor) {
        let leftPadView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textfield.frame.height))
        textfield.leftView = leftPadView
        textfield.leftViewMode = .always
        textfield.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: [
            NSAttributedString.Key.foregroundColor: placeholderColour,
            NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Light", size: 15) as Any])
    }
    
    
    func addDisclosureAccessoryView(for button: UIButton) {
        let disclosure = UITableViewCell()
        disclosure.frame = CGRect(x: 0, y: 0, width: view.frame.width - 10, height: button.frame.height)
        disclosure.accessoryType = .disclosureIndicator
        disclosure.isUserInteractionEnabled = false

        button.addSubview(disclosure)

        button.titleLabel?.textAlignment = .center
        NSLayoutConstraint.activate([(button.titleLabel?.widthAnchor.constraint(equalToConstant: button.frame.width))!])
    }
    
    
    func configureTextFieldPlaceholders(for textField: UITextField, withText: String) {
        textField.attributedPlaceholder = NSAttributedString(string: withText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
    }
    
    
    func renderCirlularImage(for image: UIImage?) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let img = renderer.image { (ctx) in
            
            image?.draw(in: CGRect(x: 0, y: 0, width: 100, height: 100))
            
            let rectangle = CGRect(x: -25, y: -25, width: 150, height: 150)
            ctx.cgContext.setStrokeColor(Settings.flipsideBlackColour.cgColor)
            ctx.cgContext.setLineWidth(50)
            ctx.cgContext.strokeEllipse(in: rectangle)
            ctx.cgContext.drawPath(using: .stroke)
        }
        return img
    }
    
    
    //MARK: - View Controller Dimissmissals
    
    func showCancelButton() {
        if #available(iOS 13.0, *) {} else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissModalVC))
        }
    }
    
    @objc func dismissModalVC() {
        dismiss(animated: true)
    }

    func popToRootController(ofTab index: Int) {
        UIApplication.shared.windows[0].rootViewController?.dismiss(animated: true, completion: {
            let tabIndex = index
            let window = UIApplication.shared.windows[0]
            let tabBar = window.rootViewController as? UITabBarController
            
            // Change the selected tab item to destination View Controller
            tabBar?.selectedIndex = tabIndex
            
            // Pop to the root controller of that tab
            if let vc = tabBar?.viewControllers?[tabIndex] as? UINavigationController {
                vc.popToRootViewController(animated: true)
            }
        })
    }
    
}

extension UIView {
    func blink(duration: TimeInterval = 0.5, delay: TimeInterval = 0.0, alpha: CGFloat = 0.0) {
        UIView.animate(withDuration: duration, delay: delay, options: [.curveEaseInOut, .repeat, .autoreverse], animations: {
            self.alpha = alpha
        })
    }
}





