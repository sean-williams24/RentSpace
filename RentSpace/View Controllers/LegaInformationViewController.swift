//
//  LegaInformationViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 19/02/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import UIKit

class LegaInformationViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet var textView: UITextView!
    @IBOutlet var titleLabel: UILabel!
    
    
    // MARK: - Properties
    
    var displayingDataFor = ""

    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = displayingDataFor
        
        switch displayingDataFor {
        case "Terms & Conditions":
            textView.text = LegalContent.TermsAndConditions.rawValue
            
        case "Privacy Policy":
            textView.text = LegalContent.PrivacyPolicy.rawValue

        case "Legal Info":
            textView.text = LegalContent.LegalInfo.rawValue

        default:
            textView.text = LegalContent.PrivacyPolicy.rawValue
        }

        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
