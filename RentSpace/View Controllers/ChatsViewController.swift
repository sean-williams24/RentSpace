//
//  ChatsViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 05/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import Firebase
import UIKit

class ChatsViewController: UIViewController, UNUserNotificationCenterDelegate {
    
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
                        let customerDisplayName = chat["customerDisplayName"],
                        let thumbnailURL = chat["thumbnailURL"] {

                        let chat = Chat(latestSender: latestSender, lastMessage: lastMessage, title: title, chatID: chatID, location: location, price: price, advertOwnerUID: advertOwnerUID, customerUID: customerUID, advertOwnerDisplayName: advertOwnerDisplayName, customerDisplayName: customerDisplayName, thumbnailURL: thumbnailURL)
                        
                        // add latest message time stamp to chat path database
                        // append first chat to temp array
                        // on 2nd chat, iterate through temp array and check if date is earlier than firat one, insert after,
                        // repeat for each one comparing dates, once you hit a date its not earlier than, insert before?
                        // might need to convert string to date
                        
                        
                        self.chats.append(chat)
                        self.tableView.reloadData()
                        
                        print("Called")

                    }
                }
            }
        })
    }
    
    
    // MARK: - Private Methods

    
    func delete(chat: Chat) {

        // Get chat to delete, setup swipe to delete and also delete from chats array
        let ac = UIAlertController(title: "Delete Advert", message: "Are you sure you wish to permanently delete your advert?", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in

            let childUpdates = ["users/\(chat.customerUID)/chats/\(chat.chatID)": NSNull(),
                                "users/\(chat.advertOwnerUID)/chats/\(chat.chatID)": NSNull(),
                                "messages/\(chat.chatID)": NSNull()]

            self.ref.updateChildValues(childUpdates) { (error, databaseRef) in
                if error != nil {
                    print(error?.localizedDescription as Any)
                }
                print("Deletion completion")

            }
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .default))

        present(ac, animated: true)
    }


}




// MARK: - TableView Delegates & Datasource

extension ChatsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        chats.count
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessagesCell", for: indexPath) as! MessagesTableViewCell
        let chat = chats[indexPath.section]
        
        var recipient = ""
        // if logged in user is advert owner, chat recipient is customer
        if Auth.auth().currentUser?.uid == chat.advertOwnerUID {
            recipient = chat.customerDisplayName
        } else {
            // if logged in user is customer, chat recipient would be advert owner
            recipient = chat.advertOwnerDisplayName
        }
        
        var you = ""
        if chat.latestSender == Auth.auth().currentUser?.displayName {
            you = "You: "
        }
        
        cell.recipientLabel.text = recipient
        cell.advertTitleLabel.text = chat.title.uppercased()
        cell.latestMessageLabel.text = "\(you)\(chat.messageBody)"
        
        if chat.thumbnailURL != "" {
            // Download image
            Storage.storage().reference(forURL: chat.thumbnailURL).getData(maxSize: INT64_MAX) { (data, error) in
                if error != nil {
                    print("Error downloading image: \(error?.localizedDescription as Any)")
                } else {
                    if let data = data {
                        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
                        let img = renderer.image { (ctx) in
                            
                            let image = UIImage(data: data)
                            image?.draw(in: CGRect(x: 0, y: 0, width: 100, height: 100))
                            
                            let rectangle = CGRect(x: -25, y: -25, width: 150, height: 150)
                            ctx.cgContext.setStrokeColor(UIColor(red:0.12, green:0.13, blue:0.14, alpha:1.0).cgColor)
                            ctx.cgContext.setLineWidth(50)
                            ctx.cgContext.strokeEllipse(in: rectangle)
                            ctx.cgContext.drawPath(using: .stroke)
                        }
                        cell.customImageView.image = img
                    }
                }
            }
        } else {
            // TODO: - load chat placeholder icon of RentSpace logo
        }
        
//        cell.layer.cornerRadius = 60
//        cell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(identifier: "MessageVC") as! MessageViewController
        let chat = chats[indexPath.section]
        vc.chat = chat
        vc.viewingExistingChat = true
        vc.chatID = chat.chatID
        
        let cell = tableView.cellForRow(at: indexPath) as! MessagesTableViewCell
        if let image = cell.customImageView.image {
            vc.thumbnail = image
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let chat = chats[indexPath.section]
        
        if editingStyle == .delete {
                let ac = UIAlertController(title: "Delete Advert", message: "Are you sure you wish to permanently delete your advert?", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in

                    let childUpdates = ["users/\(chat.customerUID)/chats/\(chat.chatID)": NSNull(),
                                        "users/\(chat.advertOwnerUID)/chats/\(chat.chatID)": NSNull(),
                                        "messages/\(chat.chatID)": NSNull()]

                    self.ref.updateChildValues(childUpdates) { (error, databaseRef) in
                        if error != nil {
                            print(error?.localizedDescription as Any)
                        }
                        print("Deletion completion")
                    }
                }))
                ac.addAction(UIAlertAction(title: "Cancel", style: .default))

                present(ac, animated: true)
            }
        
    }
}
