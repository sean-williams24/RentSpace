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
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
//        GIDSignIn.sharedInstance().signIn()
        
        let loginButton = FBLoginButton(permissions: [ .publicProfile ])
        loginButton.frame = CGRect(x: 24, y: 425, width: googleSignInButton.frame.width - 8, height: signInButton.frame.height)
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
            print(error?.localizedDescription)
            return
        }
        
        self.dismiss(animated: true) {
            //
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        print("Facebook did logout")
    }
    

    
    // MARK: - Action Methods

    @IBAction func signInButtonTapped(_ sender: Any) {
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
            if error == nil {
                self.dismiss(animated: true)
            } else {
                if let error = error, user == nil {
                    self.showAlert(title: "Problem Signing In", message: error.localizedDescription)
                }
            }
        }
    }
    
    
}
