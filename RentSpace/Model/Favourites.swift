//
//  Favourites.swift
//  RentSpace
//
//  Created by Sean Williams on 29/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

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
}
