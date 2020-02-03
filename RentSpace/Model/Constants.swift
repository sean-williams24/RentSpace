//
//  Constants.swift
//  RentSpace
//
//  Created by Sean Williams on 06/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import Firebase
import Foundation
import MapKit
import Contacts

class Constants {
    
    static var userLocationTown = ""
    static var userLocationCity = ""
    static var userLocationCountry = ""
    static var userCLLocation = CLLocation()
    static var userLocationAddress: CNPostalAddress?
    
    static var customCLLocation = CLLocation()
    static var searchDistance: Double = 20
    static var savedLocationExists = false

}



