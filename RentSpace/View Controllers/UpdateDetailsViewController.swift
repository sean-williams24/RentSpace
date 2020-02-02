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
        } else if userDetailToUpdate == "Email" {
            updateTextfield.text = Auth.auth().currentUser?.email
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
                // Not a valid display name
            }
        } else if userDetailToUpdate == "Email" {
            if isValidEmail(newCredential) {
                Auth.auth().currentUser?.updateEmail(to: newCredential) { (error) in
                    self.handleUpdateCompletion(error)
                   }
            } else {
                // Not a valid email address
            }
        } else {
            if isValidPassword(newCredential) && newCredential == confirmPasswordTextfield.text {
                Auth.auth().currentUser?.updatePassword(to: newCredential) { (error) in
                  self.handleUpdateCompletion(error)
                }
            } else {
                // PW invalid or they don't match
            }
        }
        
    }
    


}

extension UpdateDetailsViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //
    }
}
