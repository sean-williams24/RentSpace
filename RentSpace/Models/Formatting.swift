//
//  UITVCell Extension.swift
//  RentSpace
//
//  Created by Sean Williams on 18/09/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import UIKit

class Formatting {
    
    //MARK: - Tintable category icon method
    
     class func renderTemplateImage(imageName: String) -> UIImage? {
        if #available(iOS 13.0, *) {
            if let image = UIImage(systemName: imageName) {
                let templateImage = image.withRenderingMode(.alwaysTemplate)
                return templateImage
            }
        } else {
            if let image = UIImage(named: imageName) {
                let templateImage = image.withRenderingMode(.alwaysTemplate)
                return templateImage
            }
        }
        return nil
    }
    
    //MARK: - Format address for location labels from address data
    
    class func formatAddress(for advert: Space) -> String {
        
        var location = ""
        let city = advert.city
        let subAdminArea = advert.subAdminArea
        let town = advert.town
        let state = advert.state
        
        if city == subAdminArea {
            location = "\(town), \(city)"
            if town == "" {
                location = "\(city)"
            }
        } else {
            location = "\(town), \(city), \(subAdminArea)"
            if town == "" {
                location = "\(city), \(subAdminArea)"
            }
        }
        
        if city == "" && town == "" {
            location = subAdminArea
            
            if subAdminArea == "" {
                location = state
            }
        }
        
        return location
    }
    
    
    //MARK: - Format price rates

    class func priceRateFormatter(rate: String) -> String {
        switch rate {
        case "Hourly":
            return "P/H"
        case "Daily":
            return "P/D"
        case "Weekly":
            return "P/W"
        case "Monthly":
            return "P/M"
        case "Annually":
            return "P/Y"
        default:
            return "P/H"
        }
    }
}
