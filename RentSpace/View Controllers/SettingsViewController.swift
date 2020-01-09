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
    
    @IBOutlet var signOutButton: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        signOutButton.layer.cornerRadius = 5
        
        if let currentUser = Settings.currentUser?.email {
            signOutButton.setTitle("SIGN OUT (\(currentUser))", for: .normal)
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

    @IBAction func signOutButtonTapped(_ sender: Any) {
        let user = Auth.auth().currentUser!
        let onlineRef = Database.database().reference(withPath: "online/\(user.uid)")
        
        onlineRef.removeValue { (error, _) in
              if let error = error {
              print("Removing online failed: \(error)")
              return
            }
            
            do {
                try Auth.auth().signOut()
            } catch {
                print("Auth sign out failed: \(error.localizedDescription)")
            }
        }
        
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
        } catch let signOutError as NSError {
          print ("Error signing out: %@", signOutError)
        }
          
        // Log out of FaceBook
        LoginManager().logOut()

    }
}
