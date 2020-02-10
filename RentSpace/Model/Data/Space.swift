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
    let title: String
    let description: String
    let category: String
    let price: String
    let priceRate: String
    let email: String
    let phone: String
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
    let timestamp: Double
    var distance: Double
    
    init(key: String = "", title: String, description: String, category: String, price: String, priceRate: String, email: String, phone: String, photos: Dictionary<String,String>?, town: String, city: String, subAdminArea: String, postcode: String, state: String, country: String, viewOnMap: Bool, postedByUser: String, userDisplayName: String, timestamp: Double, distance: Double = 1) {
        self.ref = nil
        self.key = key
        self.title = title
        self.description = description
        self.category = category
        self.price = price
        self.priceRate = priceRate
        self.email = email
        self.phone = phone
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
        self.timestamp = timestamp
        self.distance = distance
    }
    
    
    // Failable initializer
    init?(snapshot: DataSnapshot) {
        guard
            let value = snapshot.value as? [String : AnyObject],
            let title = value["title"] as? String,
            let description = value["description"] as? String,
            let category = value["category"] as? String,
            let price = value["price"] as? String,
            let priceRate = value["priceRate"] as? String,
            let email = value["email"] as? String,
            let phone = value["phone"] as? String,
            let photos = value["photos"] as? [String : String]?,
            let town = value["town"] as? String,
            let city = value["city"] as? String,
            let subAdminArea = value["subAdminArea"] as? String,
            let postcode = value["postcode"] as? String,
            let state = value["state"] as? String,
            let country = value["country"] as? String,
            let viewOnMap = value["viewOnMap"] as? Bool,
            let postedByUser = value["postedByUser"] as? String,
            let userDisplayName = value["userDisplayName"] as? String,
            let timestamp = value["timestamp"] as? Double? else { return nil}
        
        self.ref = snapshot.ref
        self.key = snapshot.key
        self.title = title
        self.description = description
        self.category = category
        self.price = price
        self.priceRate = priceRate
        self.email = email
        self.phone = phone
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
        self.timestamp = timestamp ?? 0
        self.distance = 1
        
    }
    
    func toAnyObject() -> Any {
        return [
            "title": title,
            "description": description,
            "category": category,
            "price": price,
            "priceRate": priceRate,
            "email": email,
            "phone": phone,
            "photos": photos as Any,
            "town": town,
            "city": city,
            "subAdminArea": subAdminArea,
            "postcode": postcode,
            "state": state,
            "country": country,
            "viewOnMap": viewOnMap,
            "postedByUser": postedByUser,
            "userDisplayName": userDisplayName,
            "timestamp": timestamp
        ]
    }
}
