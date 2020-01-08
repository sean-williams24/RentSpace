//
//  SignInViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 05/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import FirebaseUI
import Firebase
import UIKit

class SignInViewController: UIViewController {
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var signInButton: UIButton!
    
    
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
    
    
    // MARK: - Sign In and Out

    func loginSession() {

    }
    
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

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
