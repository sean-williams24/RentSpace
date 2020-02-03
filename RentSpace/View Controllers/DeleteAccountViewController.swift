//
//  DeleteAccountViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 03/02/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import Firebase
import UIKit

class DeleteAccountViewController: UIViewController {
    
    let ref = Database.database().reference()
    let storageRef = Storage.storage().reference()

    var spacesToDelete: [Space] = []
    var UID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UID = Auth.auth().currentUser?.uid ?? ""
        
    }
    
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        
        let ac = UIAlertController(title: "There's No Turning Back...", message: "Are you positive you wish to permanently erase your RentSpace account?", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Do it", style: .default, handler: { _ in

            // Get all of users spaces and add to array
            self.ref.child(FirebaseClient.Path.userAdverts).observe(.value) { (snapshot) in
              
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                        let space = Space(snapshot: snapshot) {
                        self.spacesToDelete.append(space)
                    }
                }
                
                // Delete each space from adverts path and user path, and also delete images for each space from Storage
                for space in self.spacesToDelete {
                    self.ref.child("adverts/United Kingdom/\(space.category)/\(self.UID)-\(space.key)").removeValue()
                    space.ref?.removeValue()
                    
                    if let imageURLs = space.photos {
                        FirebaseClient.deleteImagesFromFirebaseCloudStorage(imageURLsDict: imageURLs) {
                            print("Images deleted for \(space.title)")
                        }
                    }
                }
                
                let user = Auth.auth().currentUser
                  
                // Delete user from Firebase
                  user?.delete { error in
                      if let error = error {
                          self.showAlert(title: "Something went wrong!", message: "We had some trouble deleting your account; please sign out and back in again, then try deleting your account.")
                        print(error.localizedDescription)
                      } else {
                          // Account deleted.
                        print("User Account deleted")
                        let ac = UIAlertController(title: "So Long...", message: "We're sorry to see you go. Your RentSpace account has been deleted, feel free to join us again in the future.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "Thanks", style: .default, handler: { _ in
                        self.navigationController?.popToRootViewController(animated: true)
                        }))
                        self.present(ac, animated: true)
                      }
                  }
                
            }

        }))
        ac.addAction(UIAlertAction(title: "CANCEL", style: .default))
        self.present(ac, animated: true)
    }
    
    
}
