//
//  PostConfirmationViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 10/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit

class PostConfirmationViewController: UIViewController {
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func viewAdvertsTapped(_ sender: Any) {
    }
    
    @IBAction func postAnotherSpaceTapped(_ sender: Any) {
        dismiss(animated: true)
    }
}
