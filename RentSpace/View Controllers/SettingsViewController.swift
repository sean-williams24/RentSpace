//
//  SettingsViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 05/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import FirebaseUI
import FacebookLogin
import UIKit



class SettingsViewController: UIViewController {
    
    @IBOutlet var signInOrOutButton: UIButton!
    @IBOutlet var displayNameLabel: UILabel!
    @IBOutlet var displayNameButton: UIButton!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var emailButton: UIButton!
    @IBOutlet var changePasswordButton: UIButton!
    @IBOutlet var updateCredentialsView: UIStackView!
    
    fileprivate var handle: AuthStateDidChangeListenerHandle!

    
    // MARK: - Life Cycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            if user != nil {
                if let currentUser = Settings.currentUser?.email {
                    self.signInOrOutButton.setTitle("SIGN OUT (\(currentUser))", for: .normal)
                    Settings.currentUser = user
                }
                
                self.displayNameLabel.text = user?.displayName
                self.emailLabel.text = user?.email
                self.updateCredentialsView.isHidden = false

                
            } else {
                self.signInOrOutButton.setTitle("SIGN IN", for: .normal)
                self.updateCredentialsView.isHidden = true
            }
        })
        

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addDisclosureAccessoryView(for: displayNameButton)
        addDisclosureAccessoryView(for: emailButton)
        addDisclosureAccessoryView(for: changePasswordButton)


    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle)

    }
    
    
    // MARK: - Private Methods

    
    fileprivate func addDisclosureAccessoryView(for button: UIButton) {
        let disclosure = UITableViewCell()
        disclosure.frame = button.bounds
        disclosure.accessoryType = .disclosureIndicator
        disclosure.isUserInteractionEnabled = false
        button.addSubview(disclosure)
    }

// MARK: - Action Methods

    @IBAction func signInOrOutButtonTapped(_ sender: Any) {
        // If there is a user signed in, log them out and set current user to nil
        if Settings.currentUser != nil {
            let firebaseAuth = Auth.auth()
            do {
              try firebaseAuth.signOut()
            } catch let signOutError as NSError {
              print ("Error signing out: %@", signOutError)
            }
              
            // Log out of FaceBook
            LoginManager().logOut()
            Settings.currentUser = nil
            
        } else {
            // If no user currently signed in, show signInVC and set delegates to update UI once signed in
            let vc = storyboard?.instantiateViewController(identifier: "SignInVC") as! SignInViewController
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            vc.delegate = self
            appDelegate.delegate = self
            
            present(vc, animated: true)
        }

    }
    
    
    @IBAction func displayNameButtonTapped(_ sender: Any) {
    }
    
    
    @IBAction func emailButtonTapped(_ sender: Any) {
    }
    
    @IBAction func changePasswordButtonTapped(_ sender: Any) {
    }
    
    @IBAction func deleteAccountButtonTapped(_ sender: Any) {
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! UpdateDetailsViewController
        let button = sender as! UIButton
        switch button.tag {
        case 0:
            vc.userDetailToUpdate = "Display Name"
        case 1:
            vc.userDetailToUpdate = "Email"
        case 2:
            vc.userDetailToUpdate = "Password"
        default:
            vc.userDetailToUpdate = ""
        }
        
    }
}


// MARK: - Update SignIn Delegate

extension SettingsViewController: UpdateSignInDelegate {
    func updateSignInButton() {
        let userEmail = Settings.currentUser?.email
        self.signInOrOutButton.setTitle("SIGN OUT (\(userEmail ?? ""))", for: .normal)
    }
    
    
}
