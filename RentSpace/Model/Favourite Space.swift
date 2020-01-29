//
//  Favourite Space.swift
//  RentSpace
//
//  Created by Sean Williams on 29/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import Foundation

struct FavouriteSpace: Equatable, Codable {
    let title: String
    let url: String
    
    init(title: String, url: String) {
        self.title = title
        self.url = url
    }
}
