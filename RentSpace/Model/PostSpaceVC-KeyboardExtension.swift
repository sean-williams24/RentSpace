//
//  PostSpaceVC-KeyboardExtension.swift
//  RentSpace
//
//  Created by Sean Williams on 01/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import Foundation
import UIKit

extension PostSpaceViewController {
    
    //MARK: - Move view when keyboard appears on bottom text field


    // - Move screen up
    @objc func keyboardWillShow(_ notifictation: Notification) {
        if currencyTextField.isEditing || priceTextField.isEditing {
            view.frame.origin.y = -getKeyboardHeight(notifictation)
        }
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
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // - Unsubscribe from keyboard notifications
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}
