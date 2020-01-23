//
//  MessageViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 05/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import UserNotifications
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
    var thumbnail = UIImage()
    
    
    
    // MARK: - Life Cycle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        customerUID = Settings.currentUser!.uid
        if let ID = advertSnapshot?.key {
            chatID = ID
        }
        
        ref = Database.database().reference()
        subscribeToKeyboardNotifications()
        configureUI()
        retrieveMessages()
        scrollToBottomMessage()
        dismissKeyboardOnViewTap()
        

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateTableContentInset()

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    
    
    // MARK: - Private Methods
    
    // Pin new messages(rows) to bottom of tableView
    func updateTableContentInset() {
        let numRows = tableView(self.tableView, numberOfRowsInSection: 0)
        // Set contentInsetTop to height of tableview
        var contentInsetTop = self.tableView.bounds.size.height
        for i in 0..<numRows {
            // Iterate through all rows getting CGRect for each
            let rowRect = self.tableView.rectForRow(at: IndexPath(item: i, section: 0))
            // Subtract each rows height from contentInsetTop
            contentInsetTop -= rowRect.size.height
            if contentInsetTop <= 0 {
                contentInsetTop = 0
            }
        }
        self.tableView.contentInset = UIEdgeInsets(top: contentInsetTop,left: 0,bottom: 0,right: 0)
    }
    
    fileprivate func configureUI() {
      
        messageTextField.layer.cornerRadius = 15
        messageTextField.layer.borderWidth = 1
        let leftPadView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: messageTextField.frame.height))
        messageTextField.leftView = leftPadView
        messageTextField.leftViewMode = .always
        
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
        imageView.image = thumbnail
        
    }
    
    fileprivate func retrieveMessages() {
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
    }
    
    func scrollToBottomMessage() {
        if messages.count == 0 { return }
        let bottomMessageIndex = IndexPath(row: tableView.numberOfRows(inSection: 0) - 1, section: 0)
        tableView.scrollToRow(at: bottomMessageIndex, at: .bottom, animated: true)
    }
    
    
    
    func sendMessage() {
        if !messageTextField.text!.isEmpty {
            sendMessageButton.isEnabled = false
            
            // If this is a new chat, set advertOwner details from advert object
            var advertOwnerUID = ""
            var advertOwnerDisplayName = ""
            if let ownerUID = advert[Advert.postedByUser] as? String, let ownerDisplayName = advert[Advert.userDisplayName] as? String {
                print(ownerUID)
                advertOwnerUID = ownerUID
                advertOwnerDisplayName = ownerDisplayName
            }
            
            // If chat already exists, set customer, advert owner data and thumbnail URL from chat data downloaded from Firebase
            var customerDisplayName = ""
            var thumbURL = ""
            if viewingExistingChat {
                advertOwnerUID = chat.advertOwnerUID
                customerUID = chat.customerUID
                customerDisplayName = chat.customerDisplayName
                advertOwnerDisplayName = chat.advertOwnerDisplayName
                thumbURL = chat.thumbnailURL
            } else {
                if let imageURLsDict = advert[Advert.photos] as? [String : String] {
                    thumbURL = imageURLsDict["image 1"] ?? ""
                }
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
                                 "advertOwnerDisplayName": advertOwnerDisplayName,
                                 "thumbnailURL": thumbURL]
            
            let existingChatData = ["title": advertTitleLabel.text!,
                                    "location": locationLabel.text!,
                                    "price": priceLabel.text!,
                                    "lastMessage": messageTextField.text!,
                                    "latestSender": Auth.auth().currentUser?.displayName,
                                    "customerUID": customerUID,
                                    "customerDisplayName": customerDisplayName,
                                    "chatID": chatID,
                                    "advertOwnerUID": advertOwnerUID,
                                    "advertOwnerDisplayName": advertOwnerDisplayName,
                                    "thumbnailURL": thumbURL]
            
            var chatData: [String:String] = [:]
            
            if viewingExistingChat {
                chatData = existingChatData as! [String : String]
            } else {
                chatData = firstChatData as! [String : String]
            }
            
            let messagesDB = Database.database().reference().child("messages/\(chatID)")
            let messageData = ["sender": Auth.auth().currentUser?.displayName, "message": messageTextField.text!, "messageDate": formatter.string(from: Date())]
            
            // Upload messages to advert owners and customers chats pathes, as well as messages path.
            advertOwnerDB.setValue(chatData) { (recipientError, recipientRef) in
                if recipientError != nil {
                    print("Error uploading to recipient DB: \(recipientError?.localizedDescription as Any)")
                    return
                } else {
                    customerDB.setValue(chatData) { (error, chatRef) in
                        if error != nil {
                            print("Error sending message: \(error?.localizedDescription as Any)")
                            return
                        } else {
                            messagesDB.childByAutoId().setValue(messageData) { (error, reference) in
                                if error != nil {
                                    print("Error sending message: \(error?.localizedDescription as Any)")
                                    return
                                } else {
                                    self.sendMessageButton.isEnabled = true
                                    self.messageTextField.text = ""
                                }
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    
    
    
    // MARK: - Action Methods
    
    
    @IBAction func pictureButtonTapped(_ sender: Any) {
    }
    
    
    @IBAction func sendMessageButtonTapped(_ sender: Any) {
        
        //        let _ = textFieldShouldReturn(messageTextField)
        
        sendMessage()

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
    
    //    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    //
    //        return true
    //
    //    }
}
