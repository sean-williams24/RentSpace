//
//  SpaceSelectionViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 06/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit

class SpaceSelectionViewController: UIViewController {
    
    @IBOutlet var artButton: UIButton!
    @IBOutlet var photographyButton: UIButton!
    @IBOutlet var musicButton: UIButton!
    @IBOutlet var deskButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure(artButton, text: "Art")
        configure(photographyButton, text: "Photography")
        configure(musicButton, text: "Music")
        configure(deskButton, text: "Desk Space")
        
        
    }
    
    func configure(_ button: UIButton, text: String) {
        button.imageView?.contentMode = .scaleAspectFill
        button.imageView?.layer.cornerRadius = 20
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 0.4
        button.layer.borderColor = UIColor.white.cgColor
        button.backgroundColor = .clear
        button.layer.shadowColor = UIColor.darkGray.cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 4
        button.layer.shadowOffset = CGSize(width: 1, height: 2)
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = UIFont.systemFont(ofSize: 20, weight: .light)
        label.font = UIFont(name: "Snell Roundhand", size: 30)
        label.textColor = .white
        label.text = text
        label.textAlignment = .center
        button.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 28),
        ])
    }

    
    // MARK: - Navigation


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! RentSpaceViewController
        let button = sender as! UIButton
        
        switch button.tag {
        case 0:
            vc.chosenCategory = "Art"
        case 1:
            vc.chosenCategory = "Photography"
        case 2:
            vc.chosenCategory = "Music"
        case 3:
            vc.chosenCategory = "Desk Space"
        default:
            vc.chosenCategory = "Art"
        }
        
    }
    
    
    
    @IBAction func buttonTapped(_ sender: UIButton) {
//        let vc = storyboard?.instantiateViewController(identifier: "RentSpaceVC") as! RentSpaceViewController
        
    }
    
}
