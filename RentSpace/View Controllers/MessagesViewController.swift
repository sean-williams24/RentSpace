//
//  MessagesViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 05/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import Firebase
import UIKit

class MessagesViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    var messages: [String] = []

    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        messages.append("Conversation")
        tableView.reloadData()
    }
    


}


// MARK: - TableView Delegates & Datasource

extension MessagesViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count  
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessagesCell", for: indexPath) as! MessagesTableViewCell
        
        cell.advertTitleLabel.text = "Conversation 1"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "MessageVC", sender: self)
    }
    
}
