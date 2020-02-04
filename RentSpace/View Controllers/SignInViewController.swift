//
//  SignInViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 05/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import FacebookLogin
import FirebaseUI
import Firebase
import GoogleSignIn
import NVActivityIndicatorView
import UIKit

protocol UpdateSignInDelegate {
    func updateSignInButton()
}

class SignInViewController: UIViewController, LoginButtonDelegate {

    
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet var googleSignInButton: GIDSignInButton!
    
    
    fileprivate var handle: AuthStateDidChangeListenerHandle!
    var delegate: UpdateSignInDelegate?
    

    // MARK: - Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
        
        handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            if user != nil {
                Settings.currentUser = user
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signInButton.layer.cornerRadius = Settings.cornerRadius
        addLeftPadding(for: emailTextField, placeholderText: "Email", placeholderColour: .gray)
        addLeftPadding(for: passwordTextField, placeholderText: "Password", placeholderColour: .gray)
        
        passwordTextField.isSecureTextEntry = true
//        dismissKeyboardOnViewTap()
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        googleSignInButton.style = .wide
        
        let loginButton = FBLoginButton(permissions: [ .publicProfile, .email ])
        loginButton.permissions = ["email"]
        
        for const in loginButton.constraints{
            if const.firstAttribute == NSLayoutConstraint.Attribute.height && const.constant == 28{
                loginButton.removeConstraint(const)
            }
        }
//        loginButton.frame = CGRect(x: 24, y: 425, width: view.frame.width - 48, height: 40)
        
        loginButton.delegate = self
        view.addSubview(loginButton)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        loginButton.leadingAnchor.constraint(equalTo: googleSignInButton.leadingAnchor, constant: 4).isActive = true
        loginButton.trailingAnchor.constraint(equalTo: googleSignInButton.trailingAnchor, constant: -4).isActive = true
        loginButton.topAnchor.constraint(equalTo: googleSignInButton.bottomAnchor, constant: 10).isActive = true
        
        
        

        
    }
    
    
    // MARK: - Config
    
    func configureAuth() {
        
        // listen for changes in the authorization state
//        handle = Auth.auth().addStateDidChangeListener({ (auth: Auth, user: User?) in
//            if user != nil {
//                self.dismiss(animated: true)
//            }
//        })
        
    }
    
    
    deinit {
//        Auth.auth().removeStateDidChangeListener(handle)
    }
    
    
    // MARK: - FaceBook Delegates
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        if error != nil {
            print(error?.localizedDescription as Any)
            return
        }
        
        guard let accessTokenString = AccessToken.current?.tokenString else { return }
        let credentials = FacebookAuthProvider.credential(withAccessToken: accessTokenString)
        
        Auth.auth().signIn(with: credentials) { (FBuser, error) in
            if error != nil {
                print("Problem signing into FireBase with Facebook:", error?.localizedDescription as Any)
                return
            }
            print("Successfully logged into FireBase with Facebook user:", FBuser as Any)
                
            self.dismiss(animated: true) {
                self.delegate?.updateSignInButton()
            }
        }

    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        print("Facebook did logout")
    }
    

    
    // MARK: - Action Methods

    @IBAction func signInButtonTapped(_ sender: Any) {
        
        
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { (authUser, error) in
            if error == nil {
                self.dismiss(animated: true)
                self.delegate?.updateSignInButton()
                
            } else {
                if let error = error, authUser == nil {
                    self.showAlert(title: "Problem Signing In", message: error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func forgotButtonTapped(_ sender: Any) {
        let ac = UIAlertController(title: "Password Problems?", message: "No worries, we'll send you a reset link...", preferredStyle: .alert)
        ac.addTextField { (textfield) in
            textfield.placeholder = "Enter your email address..."
            if self.emailTextField.text != nil {
                textfield.text = self.emailTextField.text
            }
        }
        ac.addAction(UIAlertAction(title: "SEND", style: .default, handler: { _ in
            guard let email = ac.textFields?[0].text else { return }
            Auth.auth().sendPasswordReset(withEmail: email) { (error) in
                if error != nil {
                    self.showAlert(title: "Oops!", message: "There was a problem sending the reset link, please check you've got the correct email adress and try again.")
                } else {
                    self.showAlert(title: "All Good", message: "Check your inbox...")
                }
            }
            
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .default))
        present(ac, animated: true)
        
    }
    
}
