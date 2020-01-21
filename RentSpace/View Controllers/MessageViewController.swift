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
    @IBOutlet var tableView: UITableView!
    
    var messages: [Message] = []
    var advert: [String: Any] = [:]
    var advertSnapshot: DataSnapshot?
    var ref: DatabaseReference!
    var handle: AuthStateDidChangeListenerHandle!
    var refHandle: DatabaseHandle!
    var chatID = ""
    var customerUID = ""
    var chat: Chat!
    var viewingExistingChat = false
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm E, d MMM"
        return formatter
    }()

    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        customerUID = Settings.currentUser!.uid
        if let ID = advertSnapshot?.key {
            chatID = ID
        }
        
        ref = Database.database().reference()
        subscribeToKeyboardNotifications()
        
        if viewingExistingChat {
            advertTitleLabel.text = chat.title
            locationLabel.text = chat.location
            priceLabel.text = chat.price
        } else {
            // New chat initiated
           let advertTitle = advert[Advert.title] as? String
           advertTitleLabel.text = advertTitle
            
           locationLabel.text = formatAddress(for: advert)
           if let price = advert[Advert.price] as? String, let priceRate = advert[Advert.priceRate] as? String {
               priceLabel.text = "£\(price) \(priceRateFormatter(rate: priceRate))"
           }
        }
        
        refHandle = ref.child("messages/\(chatID)").observe(.childAdded, with: { (dataSnapshot) in
            let message = Message()
            if let messageSnapshot = dataSnapshot.value as? [String: String] {
                message.messageBody = messageSnapshot["message"]!
                message.sender = messageSnapshot["sender"]!
                message.messageDate = messageSnapshot["messageDate"] ?? ""
                self.messages.append(message)
                self.tableView.reloadData()
                self.scrollToBottomMessage()
                
            }
        })
        
        scrollToBottomMessage()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    
    func scrollToBottomMessage() {
        if messages.count == 0 { return }
        let bottomMessageIndex = IndexPath(row: tableView.numberOfRows(inSection: 0) - 1, section: 0)
        tableView.scrollToRow(at: bottomMessageIndex, at: .bottom, animated: true)
    }



    @IBAction func pictureButtonTapped(_ sender: Any) {
    }
    
    
    @IBAction func sendMessageButtonTapped(_ sender: Any) {
        
        let _ = textFieldShouldReturn(messageTextField)
    }
}



// MARK: - TableView Delegates & Datasource

extension MessageViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let recipientCell = messagesTableView.dequeueReusableCell(withIdentifier: "RecipientMessageCell", for: indexPath) as! MessageTableViewCell
        let senderCell = messagesTableView.dequeueReusableCell(withIdentifier: "SenderMessageCell", for: indexPath) as! SenderTableViewCell
        let message = messages[indexPath.row]
        
        if message.sender == Auth.auth().currentUser?.displayName {
            let cell = senderCell
            cell.messageLabel.text = message.messageBody
            cell.messageContainerView.layer.cornerRadius = 8
            cell.dateLabel.text = message.messageDate
            return cell
        } else {
            let cell = recipientCell
            cell.messageLabel.text = message.messageBody
            cell.messageContainerView.layer.cornerRadius = 8
            cell.dateLabel.text = message.messageDate
            return cell
        }
        

        
        

    }
    
}


// MARK: - TextField Delegates


extension MessageViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !textField.text!.isEmpty {
//            textField.endEditing(true)
            messageTextField.isEnabled = false
            sendMessageButton.isEnabled = false
            
            var advertOwnerUID = ""
            var advertOwnerDisplayName = ""
            if let ownerUID = advert[Advert.postedByUser] as? String, let ownerDisplayName = advert[Advert.userDisplayName] as? String {
                advertOwnerUID = ownerUID
                advertOwnerDisplayName = ownerDisplayName
            }
            
            // If chat already exists, set customer and advert owner data from chat data downloaded from Firebase
            var customerDisplayName = ""
            if viewingExistingChat {
                advertOwnerUID = chat.advertOwnerUID
                customerUID = chat.customerUID
                customerDisplayName = chat.customerDisplayName
                advertOwnerDisplayName = chat.advertOwnerDisplayName
            }
            
            let customerDB = ref.child("users/\(customerUID)/chats/\(chatID)")
            let advertOwnerDB = ref.child("users/\(advertOwnerUID)/chats/\(chatID)")
            let firstChatData = ["title": advertTitleLabel.text!,
                            "location": locationLabel.text!,
                            "price": priceLabel.text!,
                            "lastMessage": messageTextField.text!,
                            "latestSender": Auth.auth().currentUser?.displayName,
                            "customerUID": Auth.auth().currentUser?.uid,
                            "customerDisplayName": Auth.auth().currentUser?.displayName,
                            "chatID": chatID,
                            "advertOwnerUID": advertOwnerUID,
                            "advertOwnerDisplayName": advertOwnerDisplayName]
            
            let existingChatData = ["title": advertTitleLabel.text!,
                                    "location": locationLabel.text!,
                                    "price": priceLabel.text!,
                                    "lastMessage": messageTextField.text!,
                                    "latestSender": Auth.auth().currentUser?.displayName,
                                    "customerUID": customerUID,
                                    "customerDisplayName": customerDisplayName,
                                    "chatID": chatID,
                                    "advertOwnerUID": advertOwnerUID,
                                    "advertOwnerDisplayName": advertOwnerDisplayName]
            
            var chatData: [String:String] = [:]
            
            if viewingExistingChat {
                chatData = existingChatData as! [String : String]
            } else {
                chatData = firstChatData as! [String : String]
            }

            let messagesDB = Database.database().reference().child("messages/\(chatID)")
            let messageData = ["sender": Auth.auth().currentUser?.displayName, "message": messageTextField.text!, "messageDate": formatter.string(from: Date())]
            
            // Set chat in advert owner/recipients database
            advertOwnerDB.setValue(chatData) { (recipientError, recipientRef) in
                if recipientError != nil {
                    print("Error uploading to recipient DB: \(recipientError?.localizedDescription as Any)")
                    return
                } else {
                    print("Message sent to recipient")
                    customerDB.setValue(chatData) { (error, chatRef) in
                        if error != nil {
                              print("Error sending message: \(error?.localizedDescription as Any)")
                              return
                        } else {
                            print("Customer DB saved in Chat")
                            
                            messagesDB.childByAutoId().setValue(messageData) { (error, reference) in
                                if error != nil {
                                    print("Error sending message: \(error?.localizedDescription as Any)")
                                    return
                                } else {
                                    print("Message Sent")
                                    
                                    self.messageTextField.isEnabled = true
                                    self.sendMessageButton.isEnabled = true
                                    self.messageTextField.text = ""

                                }
                            }
                        }
                    }
                }
            }
        }
        return true
    }
}
