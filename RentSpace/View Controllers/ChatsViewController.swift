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
                        let latestSender = chat["latestSender"],
                        let title = chat["title"],
                        let location = chat["location"],
                        let price = chat["price"],
                        let lastMessage = chat["lastMessage"],
                        let chatID = chat["chatID"],
                        let advertOwnerUID = chat["advertOwnerUID"],
                        let customerUID = chat["customerUID"],
                        let advertOwnerDisplayName = chat["advertOwnerDisplayName"],
                        let customerDisplayName = chat["customerDisplayName"] {
                        
                        let chat = Chat(latestSender: latestSender, lastMessage: lastMessage, title: title, chatID: chatID, location: location, price: price, advertOwnerUID: advertOwnerUID, customerUID: customerUID, advertOwnerDisplayName: advertOwnerDisplayName, customerDisplayName: customerDisplayName)
                        
                        self.chats.append(chat)
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
        let chat = chats[indexPath.row]
        
        var recipient = ""
        // if logged in user is advert owner, chat recipient is customer
        if Auth.auth().currentUser?.uid == chat.advertOwnerUID {
            recipient = chat.customerDisplayName
        } else {
            // if logged in user is customer, chat recipient would be advert owner
            recipient = chat.advertOwnerDisplayName
        }
        
        cell.recipientLabel.text = recipient
        cell.advertTitleLabel.text = chat.title
        cell.latestMessageLabel.text = "\(chat.latestSender): \(chat.messageBody)"
    
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
