//
//  PostConfirmationViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 10/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit

class PostConfirmationViewController: UIViewController {
    
    // MARK: - Outlets

    @IBOutlet var viewAdvertsButton: UIButton!
    @IBOutlet var postAnotherSpaceButton: UIButton!
    @IBOutlet var updateLabel: UILabel!
    
    
    // MARK: - Properties

    var updatingAdvert = false
    
    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewAdvertsButton.layer.cornerRadius = Settings.cornerRadius
        viewAdvertsButton.layer.borderWidth = 1
        viewAdvertsButton.layer.borderColor = Settings.orangeTint.cgColor
        postAnotherSpaceButton.layer.cornerRadius = Settings.cornerRadius
        
        if updatingAdvert {
            postAnotherSpaceButton.isHidden = true
            viewAdvertsButton.titleLabel?.text = "VIEW YOUR SPACES"
            updateLabel.text = "Your changes have been updated on RentSpace."
        }
    }
    
    
    // MARK: - Action Methods

    @IBAction func viewAdvertsTapped(_ sender: Any) {
        popToRootController(ofTab: 2)
    }
    
    @IBAction func postAnotherSpaceTapped(_ sender: Any) {
        dismiss(animated: true)
    }
}
