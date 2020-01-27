//
//  PostConfirmationViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 10/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit

class PostConfirmationViewController: UIViewController {
    
    @IBOutlet var viewAdvertsButton: UIButton!
    @IBOutlet var postAnotherSpaceButton: UIButton!
    @IBOutlet var updateLabel: UILabel!
    
    var updatingAdvert = false
    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewAdvertsButton.layer.cornerRadius = Settings.cornerRadius
        postAnotherSpaceButton.layer.cornerRadius = Settings.cornerRadius
        
        if updatingAdvert {
            postAnotherSpaceButton.isHidden = true
            viewAdvertsButton.titleLabel?.text = "VIEW YOUR ADVERTS"
            updateLabel.text = "Your changes have been updated on RentSpace."
        }

    }
    


    @IBAction func viewAdvertsTapped(_ sender: Any) {
        UIApplication.shared.windows[0].rootViewController?.dismiss(animated: true, completion: {
            let tabIndex = 2
            let window = UIApplication.shared.windows[0]
            let tabBar = window.rootViewController as? UITabBarController
            // Change the selected tab item to MySpacesVC
            tabBar?.selectedIndex = tabIndex
            
            // Pop to the root controller of that tab
            if let vc = tabBar?.viewControllers?[tabIndex] as? UINavigationController {
                vc.popToRootViewController(animated: true)
            }
        })
    }
    
    @IBAction func postAnotherSpaceTapped(_ sender: Any) {
        dismiss(animated: true)
    }
}
