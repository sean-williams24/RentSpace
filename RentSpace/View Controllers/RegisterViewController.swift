//
//  RegisterViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 05/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import FirebaseAuth
import UIKit

class RegisterViewController: UIViewController {
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var confirmPasswordTextField: UITextField!
    @IBOutlet var registerButton: UIButton!
    @IBOutlet var checkmark1: UIImageView!
    @IBOutlet var checkmark2: UIImageView!
    @IBOutlet var checkmark3: UIImageView!
    @IBOutlet var passwordDetailsLabel: UILabel!
    
    var emailValidated = false
    var passwordValidated = false

    override func viewDidLoad() {
        super.viewDidLoad()
        registerButton.isEnabled = false
        registerButton.backgroundColor = .darkGray
        registerButton.layer.cornerRadius = 5
        passwordDetailsLabel.alpha = 0
        configureTextFieldPlaceholders(for: emailTextField, withText: "Email")
        configureTextFieldPlaceholders(for: passwordTextField, withText: "Password")
        configureTextFieldPlaceholders(for: confirmPasswordTextField, withText: "Confirm Password")

        // Detect when a key is pressed in textfields
        emailTextField.addTarget(self, action: #selector(textFieldTyping), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldTyping), for: .editingChanged)
        confirmPasswordTextField.addTarget(self, action: #selector(textFieldTyping), for: .editingChanged)

    }
    

    
    // MARK: - Private Methods

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
    
    @objc func textFieldTyping(textField: UITextField) {
        switch textField.tag {
        case 0:
            if isValidEmail(emailTextField.text!) {
                checkmark1.tintColor = .systemPurple
                emailValidated = true
            } else {
                checkmark1.tintColor = .darkGray
            }
            passwordDetailsLabel.isHidden = true

        case 1:
            if isValidPassword(passwordTextField.text!) {
                checkmark2.tintColor = .systemPurple
            } else {
                checkmark2.tintColor = .darkGray
            }
            UIView.animate(withDuration: 4) {
                self.passwordDetailsLabel.alpha = 1
            }
        case 2:
            if confirmPasswordTextField.text! == passwordTextField.text! {
                checkmark3.tintColor = .systemPurple
                passwordValidated = true
            } else {
                checkmark3.tintColor = .darkGray
            }
            passwordDetailsLabel.isHidden = true

        default:
            print("")
        }
        
        if emailValidated == true && passwordValidated == true {
            registerButton.isEnabled = true
            registerButton.backgroundColor = .systemPurple
        }
    }
    
    
    // MARK: - Action Methods

    
    @IBAction func registerButtonTapped(_ sender: Any) {
        if let email = emailTextField.text {
            if isValidEmail(email) {
                
            }
        }
        
        Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { (authResult, regError) in
            // If user account creation is successful, sign user in and pop controller
            if regError == nil {
                Auth.auth().signIn(withEmail: self.emailTextField.text!, password: self.confirmPasswordTextField.text!) { (user, signInError) in
                    // If there is no error, sign-in successful, dismiss all view controllers
                    if signInError == nil {
                        UIApplication.shared.windows[0].rootViewController?.dismiss(animated: true, completion: {

                        })
                    } else {
                        if let error = signInError, user == nil {
                            self.showAlert(title: "Problem Signing In", message: error.localizedDescription)
                        }
                    }
                }
            } else {
                if let error = regError {
                    self.showAlert(title: "Registration Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - Text Field Delegates

extension RegisterViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    
    
    
}
