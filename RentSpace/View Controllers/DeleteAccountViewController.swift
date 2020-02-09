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
    
    //MARK: - Properties

    let ref = FirebaseClient.databaseRef
    fileprivate var refHandle: DatabaseHandle!
    var spacesToDelete: [Space] = []
    var UID = ""
    var advertPath = ""
    
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UID = Auth.auth().currentUser?.uid ?? ""
        advertPath = "users/\(UID)/adverts"
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        ref.child(advertPath).removeObserver(withHandle: refHandle)
    }
    
    
    //MARK: - Private Methods

    func deleteUserData(completion: @escaping () -> Void) {
        // Get all of users spaces and add to array
        var deletionCount = 0
        
        refHandle = self.ref.child(advertPath).observe(.value) { [weak self] (snapshot) in
            guard let self = self else { return }
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot {
                    if let space = Space(snapshot: snapshot) {
                        self.spacesToDelete.append(space)
                    }
                }
            }
            
            if self.spacesToDelete.count == 0 {
                completion()
            } else {
                // Delete each space from adverts path and user path, and also delete images for each space from Storage then call completion
                for space in self.spacesToDelete {
                    self.ref.child("adverts/United Kingdom/\(space.category)/\(self.UID)-\(space.key)").removeValue()
                    
                    if let imageURLs = space.photos {
                        FirebaseClient.deleteImagesFromFirebaseCloudStorage(imageURLsDict: imageURLs) {
                            print("Images deleted for \(space.title)")
                            deletionCount += 1
                            
                            if deletionCount == self.spacesToDelete.count {
                                self.ref.child("users/\(self.UID)").removeValue()
                                completion()
                            }
                        }
                    } else {
                        deletionCount += 1
                        
                        if deletionCount == self.spacesToDelete.count {
                            self.ref.child("users/\(self.UID)").removeValue()
                            completion()
                        }
                    }
                }
            } 
        }
    }
    
    
    //MARK: - Action Methods
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        
        let ac = UIAlertController(title: "There's No Turning Back...", message: "Are you positive you wish to permanently erase your RentSpace account?", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Do it", style: .default, handler: { _ in
            
            self.deleteUserData {
                let user = Auth.auth().currentUser
                print("Advert deletion completion - delete user >>>>")
                
                // Delete user from Firebase
                user?.delete { error in
                    if let error = error {
                        self.showAlert(title: "Something went wrong!", message: "Deleting your account requires re-authentication; please sign out and back in again, then try deleting your account.")
                        print(error.localizedDescription)
                    } else {
                        // Account deleted.
                        print("User Account deleted")
                        let ac = UIAlertController(title: "So Long...", message: "We're sorry to see you go. Your RentSpace account has been deleted, feel free to join us again in the future.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "Thanks", style: .default, handler: { _ in
                            self.popToRootController(ofTab: 0)
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
