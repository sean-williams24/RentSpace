//
//  Advert.swift
//  RentSpace
//
//  Created by Sean Williams on 04/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import Firebase
import Foundation

struct Space {
    
    let ref: DatabaseReference?
    let key: String
//    let name: String
    let title: String
    let description: String
    let category: String
    let price: String
    let priceRate: String
    let email: String
    let phone: String
//    let address: String
    let photos: Dictionary<String,String>?
    let town: String
    let city: String
    let subAdminArea: String
    let postcode: String
    let state: String
    let country: String
    let viewOnMap: Bool
    let postedByUser: String
    let userDisplayName: String
//    let timestamp: Timestamp
    
    
    init?(snapshot: DataSnapshot) {
        guard
            let value = snapshot.value as? [String : AnyObject],
//            let name = value["name"] as? String,
            let title = value["title"] as? String,
            let description = value["description"] as? String,
            let category = value["category"] as? String,
            let price = value["price"] as? String,
            let priceRate = value["priceRate"] as? String,
            let email = value["email"] as? String,
            let phone = value["phone"] as? String,
//            let address = value["address"] as? String,
            let photos = value["photos"] as? [String : String],
            let town = value["town"] as? String,
            let city = value["city"] as? String,
            let subAdminArea = value["subAdminArea"] as? String,
            let postcode = value["postcode"] as? String,
            let state = value["state"] as? String,
            let country = value["country"] as? String,
            let viewOnMap = value["viewOnMap"] as? Bool,
            let postedByUser = value["postedByUser"] as? String,
            let userDisplayName = value["userDisplayName"] as? String else { return nil }
//            let timestamp = value["timestamp"] as? Timestamp else { return nil}
        
        self.ref = snapshot.ref
        self.key = snapshot.key
//        self.name = name
        self.title = title
        self.description = description
        self.category = category
        self.price = price
        self.priceRate = priceRate
        self.email = email
        self.phone = phone
//        self.address = address
        self.photos = photos
        self.town = town
        self.city = city
        self.subAdminArea = subAdminArea
        self.postcode = postcode
        self.state = state
        self.country = country
        self.viewOnMap = viewOnMap
        self.postedByUser = postedByUser
        self.userDisplayName = userDisplayName
//        self.timestamp = timestamp
        
        
    }
    
    
    
}
