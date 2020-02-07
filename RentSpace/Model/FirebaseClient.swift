//
//  Firebase.swift
//  RentSpace
//
//  Created by Sean Williams on 03/02/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import Firebase
import Foundation


class FirebaseClient {
    
    static var currentUser: User?
    static let storageRef = Storage.storage().reference()
    static let ref = Database.database().reference()
    
    struct Path {
        static let userAdverts = "users/\(Auth.auth().currentUser?.uid ?? "")/adverts"
    }
    
    class func deleteImagesFromFirebaseCloudStorage(imageURLsDict: [String:String], completion: @escaping() -> ()) {
        let storage = Storage.storage()
        var deletedImagesCount = 0
        for (_, imageURL) in imageURLsDict {
            let storRef = storage.reference(forURL: imageURL)
            storRef.delete { (error) in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    deletedImagesCount += 1
                    print("Image Deleted: \(deletedImagesCount)")
                    if deletedImagesCount == imageURLsDict.count {
                        completion()
                    }
                }
            }
        }
    }
}
