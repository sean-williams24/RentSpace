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
    
    
}
