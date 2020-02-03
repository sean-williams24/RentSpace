//
//  UpdateDetailsViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 02/02/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import Firebase
import UIKit

class UpdateDetailsViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet var updateTextfield: UITextField!
    @IBOutlet var confirmPasswordTextfield: UITextField!
    @IBOutlet var buttonGapConstraint: NSLayoutConstraint!
    
    
    
    //MARK: - Properties
    var displayName: String!
    var emailAddress: String!
    var userDetailToUpdate: String!
    
    
    //MARK: - Lifecycle

    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        title = userDetailToUpdate
        addLeftPadding(for: updateTextfield, placeholderText: userDetailToUpdate, placeholderColour: .darkGray)
        addLeftPadding(for: confirmPasswordTextfield, placeholderText: "Confirm Password", placeholderColour: .darkGray)
        confirmPasswordTextfield.isHidden = true

        if userDetailToUpdate == "Display Name" {
            updateTextfield.text = Auth.auth().currentUser?.displayName
            buttonGapConstraint.constant = 22
        } else if userDetailToUpdate == "Email" {
            updateTextfield.text = Auth.auth().currentUser?.email
            buttonGapConstraint.constant = 22
        } else {
            updateTextfield.isSecureTextEntry = true
            confirmPasswordTextfield.isSecureTextEntry = true
            confirmPasswordTextfield.isHidden = false
        }

        
    }
    
    //MARK: - Private Methods

    
    fileprivate func handleUpdateCompletion(_ error: Error?) {
        if error != nil {
            showAlert(title: "Oops!", message: error?.localizedDescription)
        } else {
            let ac = UIAlertController(title: "\(self.userDetailToUpdate!) Updated", message: nil, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(ac, animated: true)
        }
    }
    
    
    //MARK: - Action Methods

    
    @IBAction func updateButtonTapped(_ sender: Any) {
        guard let newCredential = updateTextfield.text else { return }
        
        if userDetailToUpdate == "Display Name" {
            if isValidDisplayName(newCredential) {
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = self.updateTextfield.text
                changeRequest?.commitChanges { (error) in
                    self.handleUpdateCompletion(error)
                }
            } else {
                showAlert(title: "Whoops!", message: "Display name needs to be at least 3 characters...")
            }
        } else if userDetailToUpdate == "Email" {
            if isValidEmail(newCredential) {
                Auth.auth().currentUser?.updateEmail(to: newCredential) { (error) in
                    self.handleUpdateCompletion(error)
                   }
            } else {
                showAlert(title: "Oh No!", message: "That doesn't appear to be a valid email address...")
            }
        } else {
            if isValidPassword(newCredential) && newCredential == confirmPasswordTextfield.text {
                Auth.auth().currentUser?.updatePassword(to: newCredential) { (error) in
                  self.handleUpdateCompletion(error)
                }
            } else {
                showAlert(title: "Hmmm", message: "Password must contain at least 6 characters, 1 uppercase letter, 1 lowercase letter and 1 number.")
            }
        }
        
    }
    


}

extension UpdateDetailsViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //
    }
}
