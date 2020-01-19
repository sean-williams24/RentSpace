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
                        let location = chat["location"],
                        let price = chat["price"],
                        let lastMessage = chat["lastMessage"],
                        let chatID = chat["chatID"],
                        let advertOwnerUID = chat["advertOwnerUID"],
                        let customerUID = chat["customerUID"]{
                        let message = Chat(sender: sender, lastMessage: lastMessage, title: title, chatID: chatID, location: location, price: price, advertOwnerUID: advertOwnerUID, customerUID: customerUID)
                        self.chats.append(message)
                        self.tableView.reloadData()
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
        vc.chat = chat
        vc.viewingExistingChat = true
        vc.chatID = chat.chatID
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
