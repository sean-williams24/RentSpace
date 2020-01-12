//
//  PostConfirmationViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 10/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit

class PostConfirmationViewController: UIViewController {
    
    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    


    @IBAction func viewAdvertsTapped(_ sender: Any) {
        dismiss(animated: true) {
            let tabIndex = 2
            let window = UIApplication.shared.windows[0]
            let tabBar = window.rootViewController as? UITabBarController
            // Change the selected tab item to MySpacesVC
            tabBar?.selectedIndex = tabIndex
            
            // Pop to the root controller of that tab
            if let vc = tabBar?.viewControllers?[tabIndex] as? UINavigationController {
                vc.popToRootViewController(animated: true)
            }
        }
    }
    
    @IBAction func postAnotherSpaceTapped(_ sender: Any) {
        dismiss(animated: true)
    }
}
