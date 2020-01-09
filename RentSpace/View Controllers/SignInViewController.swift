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
import UIKit

class SignInViewController: UIViewController, LoginButtonDelegate {
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet var googleSignInButton: GIDSignInButton!
    
    
    fileprivate var handle: AuthStateDidChangeListenerHandle!
    var user: User?
    var displayName = ""
    

    // MARK: - Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
        configureAuth()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signInButton.layer.cornerRadius = 5
        configureTextFieldPlaceholders(for: emailTextField, withText: "Email")
        configureTextFieldPlaceholders(for: passwordTextField, withText: "Password")
        
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
//        GIDSignIn.sharedInstance().signIn()
        
        let loginButton = FBLoginButton(permissions: [ .publicProfile, .email ])
        loginButton.permissions = ["email"]
        
        // TODO - try to use constraints instead of frame
        loginButton.frame = CGRect(x: 24, y: 425, width: view.frame.width - 48, height: signInButton.frame.height)
        loginButton.delegate = self
        view.addSubview(loginButton)
        
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
                
            self.dismiss(animated: true)
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
            } else {
                if let error = error, authUser == nil {
                    self.showAlert(title: "Problem Signing In", message: error.localizedDescription)
                }
            }
        }
    }
    
    
}
