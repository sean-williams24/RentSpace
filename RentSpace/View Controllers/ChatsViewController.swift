//
//  ChatsViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 05/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import Firebase
import UIKit

class ChatsViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    var chats: [Chat] = []
//    var advertSnapshot: DataSnapshot!
//    var advert: [String: Any] = [:]
    var refHandle: DatabaseHandle!
    var ref: DatabaseReference!


    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        let UID = Settings.currentUser!.uid
        ref = Database.database().reference()
        
        refHandle = ref.child("users/\(UID)/chats").observe(.value, with: { (dataSnapshot) in
            self.chats.removeAll()
            for child in dataSnapshot.children {
                if let snapshot = child as? DataSnapshot {
                    print("we got the snapshot")
                    if  let chat = snapshot.value as? [String: String],
                        let sender = chat["sender"],
                        let title = chat["title"],
                        let messageBody = chat["messageBody"],
                        let chatID = chat["chatID"] {
                        let message = Chat(sender: sender, messageBody: messageBody, title: title, chatID: chatID)
                        self.chats.append(message)
                        self.tableView.reloadData()
                        print(self.chats.count)
                        print(chatID)
                    }
                }
            }
        })
        
    }
    


}


// MARK: - TableView Delegates & Datasource

extension ChatsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessagesCell", for: indexPath) as! MessagesTableViewCell
        let message = chats[indexPath.row]
        
        cell.recipientLabel.text = "RECIPIENT"
        cell.advertTitleLabel.text = message.title
        cell.latestMessageLabel.text = "\(message.sender): \(message.messageBody)"
    
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(identifier: "MessageVC") as! MessageViewController
        let chat = chats[indexPath.row]
        vc.chatID = chat.chatID
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
