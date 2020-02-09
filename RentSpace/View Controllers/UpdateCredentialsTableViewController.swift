//
//  UpdateCredentialsTableViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 03/02/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import Firebase
import UIKit

class UpdateCredentialsTableViewController: UITableViewController {

    // MARK: - Outlets

    @IBOutlet var displayNameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    
    
    // MARK: - Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        displayNameLabel.text = Auth.auth().currentUser?.displayName
        emailLabel.text = Auth.auth().currentUser?.email
    }

    // MARK: - Table view delegates

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var destination = UIViewController()
        let updateVC = storyboard?.instantiateViewController(identifier: "UpdateDetailsVC") as! UpdateDetailsViewController
        let deleteVC = storyboard?.instantiateViewController(identifier: "DeleteAccountVC") as! DeleteAccountViewController
        destination = updateVC
        
        switch indexPath.row {
        case 0:
            updateVC.userDetailToUpdate = "Display Name"
        case 1:
            updateVC.userDetailToUpdate = "Email"
        case 2:
            updateVC.userDetailToUpdate = "Password"
        case 3:
            destination = deleteVC
        default:
            updateVC.userDetailToUpdate = ""
        }
        
        show(destination, sender: self)
    }
}
