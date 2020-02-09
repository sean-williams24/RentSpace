//
//  UpdateDetailsViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 02/02/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import Firebase
import NVActivityIndicatorView
import UIKit

class UpdateDetailsViewController: UIViewController {
    
    //MARK: - Outlets
    
    @IBOutlet var updateTextfield: UITextField!
    @IBOutlet var confirmPasswordTextfield: UITextField!
    @IBOutlet var buttonGapConstraint: NSLayoutConstraint!
    @IBOutlet var loadingView: UIView!
    @IBOutlet var activityView: NVActivityIndicatorView!
    @IBOutlet var updateButton: UIButton!
    
    
    //MARK: - Properties
    
    var displayName: String!
    var emailAddress: String!
    var userDetailToUpdate: String!
    var refHandle: DatabaseHandle!
    var ref = FirebaseClient.databaseRef
    var UID = ""
    
    
    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
                
        title = userDetailToUpdate
        self.navigationController?.navigationBar.titleTextAttributes = Settings.navBarTitleAttributes
        
        addLeftPadding(for: updateTextfield, placeholderText: userDetailToUpdate, placeholderColour: .darkGray)
        addLeftPadding(for: confirmPasswordTextfield, placeholderText: "Confirm Password", placeholderColour: .darkGray)
        confirmPasswordTextfield.isHidden = true
        UID = Auth.auth().currentUser?.uid ?? ""


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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        ref.child("users/\(UID)/adverts").removeObserver(withHandle: refHandle)

    }
    
    
    //MARK: - Private Methods

    fileprivate func handleUpdateCompletion(_ error: Error?) {
        updateLoadingUI(false)

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
    
    
    fileprivate func updateLoadingUI(_ loading: Bool) {
        UIView.animate(withDuration: 0.2) {
            if loading {
                self.loadingView.alpha = 0.7
                self.activityView.startAnimating()
                self.updateTextfield.isEnabled = false
                self.updateButton.isEnabled = false
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.loadingView.alpha = 0
                    self.activityView.stopAnimating()
                    self.updateTextfield.isEnabled = true
                    self.updateButton.isEnabled = true
                }
            }
        }
    }
    
    
    //MARK: - Action Methods

    @IBAction func updateButtonTapped(_ sender: Any) {
        guard let newCredential = updateTextfield.text else { return }
        updateLoadingUI(true)
        
        if userDetailToUpdate == "Display Name" {
            if isValidDisplayName(newCredential) {
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = self.updateTextfield.text
                changeRequest?.commitChanges { (error) in
                    self.handleUpdateCompletion(error)
                                        
                    if error == nil {
                        // Update user display name on all of users adverts
                        self.refHandle = self.ref.child("users/\(self.UID)/adverts").observe(.value, with: { (snapshot) in
                            for child in snapshot.children {
                                if let snapshot = child as? DataSnapshot,
                                    let space = Space(snapshot: snapshot) {
                                    
                                    self.ref.child("users/\(self.UID)/adverts").child(space.key).updateChildValues(["userDisplayName": newCredential])

                                }
                            }
                        })
                        
                        // Update chats with new display name
                        self.ref.child("users/\(self.UID)/chats").observe(.value) { (snapshot) in
                            for child in snapshot.children {
                                if let snapshot = child as? DataSnapshot,
                                    let chat = Chat(snapshot: snapshot) {
                                    
                                    if chat.advertOwnerUID == self.UID {
                                        self.ref.child("users/\(self.UID)/chats").child(chat.chatID).updateChildValues(["advertOwnerDisplayName": newCredential])
                                        self.ref.child("users/\(chat.customerUID)/chats").child(chat.chatID).updateChildValues(["advertOwnerDisplayName": newCredential])
                                    } else {
                                        self.ref.child("users/\(self.UID)/chats").child(chat.chatID).updateChildValues(["customerDisplayName": newCredential])
                                        self.ref.child("users/\(chat.advertOwnerUID)/chats").child(chat.chatID).updateChildValues(["customerDisplayName": newCredential])
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                updateLoadingUI(false)
                showAlert(title: "Whoops!", message: "Display name needs to be at least 3 characters...")
            }
        } else if userDetailToUpdate == "Email" {
            if isValidEmail(newCredential) {
                Auth.auth().currentUser?.updateEmail(to: newCredential) { (error) in
                    self.handleUpdateCompletion(error)
                   }
            } else {
                updateLoadingUI(false)
                showAlert(title: "Oh No!", message: "That doesn't appear to be a valid email address...")
            }
        } else {
            if isValidPassword(newCredential) && newCredential == confirmPasswordTextfield.text {
                Auth.auth().currentUser?.updatePassword(to: newCredential) { (error) in
                  self.handleUpdateCompletion(error)
                }
            } else {
                updateLoadingUI(false)
                showAlert(title: "Hmmm", message: "Password must contain at least 6 characters, 1 uppercase letter, 1 lowercase letter and 1 number.")
            }
        }
    }
}

