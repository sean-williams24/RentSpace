//
//  Settings.swift
//  RentSpace
//
//  Created by Sean Williams on 09/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import FirebaseUI
import Foundation

struct Settings {
    static var appID = "572159233515806"
    
    // UIView Formatting
    static var cornerRadius: CGFloat = 25

    // Colours
    static var orangeTint = UIColor(red:0.89, green:0.39, blue:0.00, alpha:1.0)
    static var flipsideBlackColour = UIColor(red:0.12, green:0.13, blue:0.14, alpha:1.0)
    
    // Fonts / Attributes
    static let barButtonAttributes: [NSAttributedString.Key : Any] = [.font: UIFont(name: "HelveticaNeue-Light", size: 15) as Any]
    static let tabBarAttributes: [NSAttributedString.Key : Any] = [.font: UIFont(name: "HelveticaNeue-Light", size: 10) as Any]
    static let infoLabelAttributes: [NSAttributedString.Key : Any] = [.font: UIFont(name: "HelveticaNeue-Bold", size: 17) as Any]
    static let navBarTitleAttributes: [NSAttributedString.Key : Any] = [
        .font: UIFont(name: "HelveticaNeue-Light", size: 20)!,
        .foregroundColor: UIColor.white]

    // Firebase
    static var currentUser: User?
    
    static var signingOut = false

}
