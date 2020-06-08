//
//  Favourites.swift
//  RentSpace
//
//  Created by Sean Williams on 29/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//
import Firebase
import Foundation

struct Favourites {
    static var spaces = [FavouriteSpace]()
}

struct FavouriteSpace: Equatable, Codable {
    let key: String
    let url: String
    
    init(key: String, url: String) {
        self.key = key
        self.url = url
    }
    
    init?(snapshot: DataSnapshot) {
        guard let value = snapshot.value as? [String:String],
            let key = value["key"],
            let url = value["url"] else { return nil }

        self.key = key
        self.url = url
    }
    
    func toDictionaryObject() -> [String:String] {
        return ["key": key, "url": url]
    }
}
