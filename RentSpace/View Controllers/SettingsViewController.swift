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
    
    fileprivate var handle: AuthStateDidChangeListenerHandle!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("Appear VIEW")
        
        handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            if user != nil {
                if let currentUser = Settings.currentUser?.email {
                    self.signInOrOutButton.setTitle("SIGN OUT (\(currentUser))", for: .normal)
                    Settings.currentUser = user
                }
            } else {
                self.signInOrOutButton.setTitle("SIGN IN", for: .normal)
            }
        })
        

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signInOrOutButton.layer.cornerRadius = 5
        

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        Auth.auth().removeStateDidChangeListener(handle)

    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

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
}

extension SettingsViewController: UpdateSignInDelegate {
    func updateSignInButton() {
        let userEmail = Settings.currentUser?.email
        self.signInOrOutButton.setTitle("SIGN OUT (\(userEmail ?? ""))", for: .normal)
    }
    
    
}
