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

protocol userDidSignOutDelegate {
    func removeUserData()
}

class SettingsViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet var signInOrOutButton: UIButton!
    @IBOutlet var updateDetailsButton: UIButton!
    @IBOutlet var termsAndConditionsButton: UIButton!
    @IBOutlet var privacyPolicyButton: UIButton!
    @IBOutlet var legalInfoButton: UIButton!
    
    
    // MARK: - Properties
    
    fileprivate var handle: AuthStateDidChangeListenerHandle!
    var delegate: userDidSignOutDelegate?
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addDisclosureAccessoryView(for: updateDetailsButton)
        addDisclosureAccessoryView(for: termsAndConditionsButton)
        addDisclosureAccessoryView(for: privacyPolicyButton)
        addDisclosureAccessoryView(for: legalInfoButton)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        
        handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            if user != nil {
                if let currentUser = Settings.currentUser?.email {
                    self.signInOrOutButton.setTitle("SIGN OUT (\(currentUser))", for: .normal)
                    Settings.currentUser = user
                }
                self.updateDetailsButton.isHidden = false
                
            } else {
                Favourites.spaces.removeAll()
                self.delegate?.removeUserData()
                self.signInOrOutButton.setTitle("SIGN IN", for: .normal)
                self.updateDetailsButton.isHidden = true
                self.popToRootController(ofTab: 0)
            }
        })
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle)
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let button = sender as? UIButton
        if button?.tag != 0 {
           let vc = segue.destination as! LegaInformationViewController
            
            switch button?.tag {
            case 1:
                vc.displayingDataFor = "Terms & Conditions"

            case 2:
                vc.displayingDataFor = "Privacy Policy"

            case 3:
                vc.displayingDataFor = "Legal Info"

            default:
                vc.displayingDataFor = "Privacy Policy"
            }
        }
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
                showAlert(title: "Yikes", message: "We may have had problems signing you out, please try again.")
            }
            
            // Log out of FaceBook
            LoginManager().logOut()
            Settings.currentUser = nil
            
            let index = 0
            let window = (UIApplication.shared.delegate as? AppDelegate)?.window
            let tabBar :UITabBarController? =  window?.rootViewController as? UITabBarController
            tabBar?.selectedIndex = index
            
            if let nav = tabBar?.viewControllers?[index] as? UINavigationController {
                nav.popToRootViewController(animated: true)
                Settings.signingOut = true
            }
        } else {
            // If no user currently signed in, show signInVC and set delegates to update UI once signed in
            let vc = storyboard?.instantiateViewController(withIdentifier: "SignInVC") as! SignInViewController
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            vc.delegate = self
            appDelegate.delegate = self
            
            present(vc, animated: true)
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


