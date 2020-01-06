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
        handle = Auth.auth().addStateDidChangeListener({ (auth: Auth, user: User?) in
            
            // check if there is a current user
            if let activeUser = user {
                // check if the current app user is the current FIRUser
                if self.user != activeUser {
                    self.user = activeUser
                    let name = user!.email!.components(separatedBy: "@")[0]
                    self.displayName = name
                }
            } else {
                // user must sign in
                self.loginSession()
            }
        })
        
    }
    
    
    deinit {
        Auth.auth().removeStateDidChangeListener(handle)
    }
    
    
    // MARK: - Sign In and Out

    func loginSession() {
//        let authViewController = FUIAuth.defaultAuthUI()!.authViewController()
//        present(authViewController, animated: true)
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
    }
    
    
}
