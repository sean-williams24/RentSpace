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
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    func showAlertWithCompletion(title: String, message: String?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
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
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height 
    }

    // - Make view controller subscribe to keyboard notifications
    func subscribeToKeyboardNotificationsPostVC() {
        NotificationCenter.default.addObserver(self, selector: #selector(PostSpaceViewController.keyboardWillShowOnPostVC(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // - Make view controller subscribe to keyboard notifications
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // - Unsubscribe from keyboard notifications
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    //MARK: - Format address for location labels from address data
    
    func formatAddress(for advert: [String : Any]) -> String {
        
        var location = ""
        let city = advert[Advert.city] as? String ?? ""
        let subAdminArea = advert[Advert.subAdminArea] as? String ?? ""
        let town = advert[Advert.town] as? String ?? ""
        
        if city == subAdminArea {
            location = "\(town), \(city)"
            if town == "" {
                location = "\(city)"
            }
        } else {
            location = "\(town), \(city), \(subAdminArea)"
            if town == "" {
                location = "\(city), \(subAdminArea)"
//                if city == "" {
//                    location = "\(subAdminArea)"
//                }
            }
        }
        
        if location == ", " {
            location = advert[Advert.address] as? String ?? ""
        }
        return location
    }
    
    
    //MARK: - Format custom textfield placeholders 

    func configureTextFieldPlaceholders(for textField: UITextField, withText: String) {
        textField.attributedPlaceholder = NSAttributedString(string: withText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
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
    
    
    //MARK: - Delete file at URL on disk
    
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
    
    //MARK: - Dismiss keyboard when view is tapped

    func dismissKeyboardOnViewTap() {
        // Keyboard dismissal
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        view.addGestureRecognizer(tap)
    }
    
    
    //MARK: - Show/Hide loading animations
    
    
    func showLoadingUI(_ loading: Bool, for activityView: NVActivityIndicatorView, label: UILabel) {
        if loading {
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
    
 
}






