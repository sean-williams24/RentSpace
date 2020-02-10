//
//  RegisterViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 05/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import FirebaseAuth
import NVActivityIndicatorView
import UIKit

protocol RegisterDelegate {
    func adjustViewAfterRegistration()
}

class RegisterViewController: UIViewController {
    
    //MARK: - Outlets

    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var confirmPasswordTextField: UITextField!
    @IBOutlet var displayNameTextField: UITextField!
    @IBOutlet var registerButton: UIButton!
    @IBOutlet var checkmark1: UIImageView!
    @IBOutlet var checkmark2: UIImageView!
    @IBOutlet var checkmark3: UIImageView!
    @IBOutlet var checkmark4: UIImageView!
    @IBOutlet var passwordDetailsLabel: UILabel!
    @IBOutlet var loadingView: UIView!
    @IBOutlet var activityView: NVActivityIndicatorView!
    @IBOutlet var successView: UIView!
    @IBOutlet var excellentButton: UIButton!
    @IBOutlet var blurredView: UIVisualEffectView!
    @IBOutlet var successViewCenterYConstraint: NSLayoutConstraint!
    
    
    //MARK: - Properties

    var emailValidated = false
    var password1Validated = false
    var password2Validated = false
    var displayNameValidated = false
    var delegate: RegisterDelegate?
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerButton.isEnabled = false
        registerButton.backgroundColor = .darkGray
        registerButton.layer.cornerRadius = Settings.cornerRadius
        passwordDetailsLabel.alpha = 0
        successView.layer.cornerRadius = 10
        successView.layer.masksToBounds = true
        blurredView.alpha = 0

        addLeftPadding(for: displayNameTextField, placeholderText: "Display Name", placeholderColour: .gray)
        addLeftPadding(for: emailTextField, placeholderText: "Email", placeholderColour: .gray)
        addLeftPadding(for: passwordTextField, placeholderText: "Password", placeholderColour: .gray)
        addLeftPadding(for: confirmPasswordTextField, placeholderText: "Confirm Password", placeholderColour: .gray)
        
        passwordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true
        
        // Detect when a key is pressed in textfields
        emailTextField.addTarget(self, action: #selector(textFieldTyping), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldTyping), for: .editingChanged)
        confirmPasswordTextField.addTarget(self, action: #selector(textFieldTyping), for: .editingChanged)
        displayNameTextField.addTarget(self, action: #selector(textFieldTyping), for: .editingChanged)
        
        dismissKeyboardOnViewTap()
    }
    
    
    // MARK: - Private Methods
    
    @objc func textFieldTyping(textField: UITextField) {
        switch textField.tag {
        case 0:
            if isValidEmail(emailTextField.text!) {
                checkmark1.tintColor = Settings.orangeTint
                emailValidated = true
            } else {
                checkmark1.tintColor = .darkGray
                emailValidated = false
            }
            
        case 1:
            if isValidPassword(passwordTextField.text!) {
                checkmark2.tintColor = Settings.orangeTint
                password1Validated = true
            } else {
                checkmark2.tintColor = .darkGray
                registerButton.isEnabled = false
                registerButton.backgroundColor = .darkGray
                password1Validated = false
            }
            
            UIView.animate(withDuration: 4) {
                self.passwordDetailsLabel.alpha = 1
            }
            
        case 2:
            if confirmPasswordTextField.text! == passwordTextField.text! {
                checkmark3.tintColor = Settings.orangeTint
                password2Validated = true
            } else {
                checkmark3.tintColor = .darkGray
                password2Validated = false
            }
            
        case 3:
            if isValidDisplayName(displayNameTextField.text!) {
                checkmark4.tintColor = Settings.orangeTint
                displayNameValidated = true
            } else {
                checkmark4.tintColor = .darkGray
                displayNameValidated = false
            }
            
        default:
            print("")
        }
        
        if emailValidated == true && password1Validated == true && password2Validated && displayNameValidated == true {
            registerButton.isEnabled = true
            registerButton.backgroundColor = Settings.orangeTint
        } else {
            registerButton.isEnabled = false
            registerButton.backgroundColor = .darkGray
        }
    }
    
    
    fileprivate func signIntoFirebase() {
        Auth.auth().signIn(withEmail: self.emailTextField.text!, password: self.confirmPasswordTextField.text!) { (user, signInError) in
            // If there is no error, sign-in successful, dismiss all view controllers
            if signInError == nil {
                self.delegate?.adjustViewAfterRegistration()
                UIApplication.shared.windows[0].rootViewController?.dismiss(animated: true)
            } else {
                if let error = signInError, user == nil {
                    self.showAlert(title: "Problem Signing In", message: error.localizedDescription)
                }
            }
        }
    }
    
    
    // MARK: - Action Methods
    
    @IBAction func registerButtonTapped(_ sender: Any) {
        self.view.endEditing(true)
        self.activityView.startAnimating()
        blurredView.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.blurredView.alpha = 1
        }

        Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { (authResult, regError) in
            // If user account creation is successful, save displayName
            if regError == nil {
                self.delegate?.adjustViewAfterRegistration()
                
                let changeRequest = authResult?.user.createProfileChangeRequest()
                changeRequest?.displayName = self.displayNameTextField.text!
                changeRequest?.commitChanges(completion: { (error) in
                    if error != nil {
                        // Error saving display name
                        print(error?.localizedDescription as Any)
                        self.activityView.stopAnimating()
                        
                        let ac = UIAlertController(title: "Problem Saving Display Name", message: "Please update your display name in settings before posting a space", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                            self.popToRootController(ofTab: 2)
                        }))
                        self.present(ac, animated: true)
                        
                    } else {
                        // successfully saved display name - show successview so user can sign in
                        self.activityView.stopAnimating()
                        UIView.animate(withDuration: 1) {
                            self.successView.alpha = 1
                        }
                    }
                })
            } else {
                if let error = regError {
                    self.activityView.stopAnimating()
                    self.showAlert(title: "Registration Error", message: error.localizedDescription)
                    self.blurredView.alpha = 0
                }
            }
        }
    }
    
    
    @IBAction func excellentButtonTapped(_ sender: Any) {
        self.signIntoFirebase()
    }
}


// MARK: - Text Field Delegates

extension RegisterViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
