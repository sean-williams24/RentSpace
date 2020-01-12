//
//  MessageViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 05/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import Firebase
import UIKit

class MessageViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var advertTitleLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var messagesTableView: UITableView!
    @IBOutlet var pictureButton: UIButton!
    @IBOutlet var messageTextField: UITextField!
    @IBOutlet var sendMessageButton: UIButton!
    
    let messages: [DataSnapshot] = []

    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    



    @IBAction func pictureButtonTapped(_ sender: Any) {
    }
    
    
    @IBAction func sendMessageButtonTapped(_ sender: Any) {
    }
}



// MARK: - TableView Delegates & Datasource

extension MessageViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        messages.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 5
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = messagesTableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        
        
        return cell
    }
    
    
    
}
