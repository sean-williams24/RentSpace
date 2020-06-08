//
//  Photo.swift
//  RentSpace
//
//  Created by Sean Williams on 27/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import Foundation

class Image: NSObject, Codable {
    var imageName: String
    
    init(imageName: String) {
        self.imageName = imageName
    }
}
