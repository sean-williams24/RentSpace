//
//  MessageViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 05/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import UserNotifications
import Firebase
import NVActivityIndicatorView
import UIKit

class MessageViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var advertTitleLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var messagesTableView: UITableView!
    @IBOutlet var pictureButton: UIButton!
    @IBOutlet var messageTextField: UITextField!
    @IBOutlet var sendMessageButton: UIButton!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var activityView: NVActivityIndicatorView!
    @IBOutlet var loadingLabel: UILabel!
    
    var messages: [Message] = []
    var space: Space!
//    var advertSnapshot: DataSnapshot?
    var ref: DatabaseReference!
    var handle: AuthStateDidChangeListenerHandle!
    var refHandle: DatabaseHandle!
    var chatID = ""
    var customerUID = ""
    var chat: Chat!
    var viewingExistingChat = false
    let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss E, d MMM, yyyy"
        return formatter
    }()
    var thumbnail = UIImage()
    var messageRead = "false"
    var previousMessageDate = ""
    
    
    
    // MARK: - Life Cycle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let UID = Settings.currentUser?.uid {
            customerUID = UID
        }
        
        // If arriving from AdvertDetailsVC, this is a new chat - create new unique chat ID using current users UID + advert key
        if !viewingExistingChat {
            chatID = customerUID + "-" + space.key
        }
        
        ref = Database.database().reference()
        subscribeToKeyboardNotifications()
        configureUI()
        listenForNewMessages()
        scrollToBottomMessage()
        dismissKeyboardOnViewTap()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateTableContentInset()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ref.child("messages/\(chatID)").removeObserver(withHandle: refHandle)
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
      
        messageTextField.layer.cornerRadius = 20
        messageTextField.layer.borderWidth = 1
        messageTextField.layer.borderColor = UIColor.darkGray.cgColor
        addLeftPadding(for: messageTextField, placeholderText: "Message...", placeholderColour: .gray)
//        let leftPadView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: messageTextField.frame.height))
//        messageTextField.leftView = leftPadView
//        messageTextField.leftViewMode = .always
        
        if viewingExistingChat {
            advertTitleLabel.text = chat.title
            locationLabel.text = chat.location
            priceLabel.text = chat.price
            self.showLoadingUI(true, for: self.activityView, label: self.loadingLabel)
        } else {
            // New chat initiated
            let advertTitle = space.title
            advertTitleLabel.text = advertTitle
            locationLabel.text = formatAddress(for: space)
            priceLabel.text = "£\(space.price) \(priceRateFormatter(rate: space.priceRate))"
        }
        imageView.image = thumbnail
    }
    
    fileprivate func listenForNewMessages() {
        refHandle = ref.child("messages/\(chatID)").observe(.value, with: { (dataSnapshot) in
            var newMessages: [Message] = []
            
            for child in dataSnapshot.children {
                if let messageSnapshot = child as? DataSnapshot {
                    if let message = Message(snapshot: messageSnapshot) {
                        newMessages.append(message)
                        
                        // If sender of message is not signed in user
                        if message.sender != Auth.auth().currentUser?.displayName {
                            //Update message as read
                            let customerDB = self.ref.child("users/\(self.chat.customerUID)/chats")
                            let advertOwnerDB = self.ref.child("users/\(self.chat.advertOwnerUID)/chats")
                            customerDB.child(self.chatID).updateChildValues(["read": "true"])
                            advertOwnerDB.child(self.chatID).updateChildValues(["read": "true"])
                        }
                    }
                }
            }
            self.messages = newMessages
            self.showLoadingUI(false, for: self.activityView, label: self.loadingLabel)
            self.tableView.reloadData()
            self.scrollToBottomMessage()

//            if let messageSnapshot = dataSnapshot.value as? [String: String] {
//                message.messageBody = messageSnapshot["message"]!
//                message.sender = messageSnapshot["sender"]!
//                message.messageDate = messageSnapshot["messageDate"] ?? ""
//                self.showLoadingUI(false, for: self.activityView, label: self.loadingLabel)
//
//                self.messages.append(message)
//                self.tableView.reloadData()
//                print("Reload data")
//            }
        })
    }
    
    func scrollToBottomMessage() {
        if messages.count == 0 { return }
        let bottomMessageIndex = IndexPath(row: tableView.numberOfRows(inSection: 0) - 1, section: 0)
        tableView.scrollToRow(at: bottomMessageIndex, at: .bottom, animated: true)
    }
    
    
    func sendMessage() {
        if !messageTextField.text!.isEmpty || messageRead == "true" {
            sendMessageButton.isEnabled = false
            
            var advertOwnerUID = ""
            var advertOwnerDisplayName = ""
            var customerDisplayName = ""
            var thumbURL = ""
            
            // If chat already exists, set customer, advert owner data and thumbnail URL from chat data downloaded from Firebase
            if viewingExistingChat {
                advertOwnerUID = chat.advertOwnerUID
                customerUID = chat.customerUID
                customerDisplayName = chat.customerDisplayName
                advertOwnerDisplayName = chat.advertOwnerDisplayName
                thumbURL = chat.thumbnailURL
            } else {
                // If this is a new chat, set advertOwner details from advert object
                advertOwnerUID = space.postedByUser
                advertOwnerDisplayName = space.userDisplayName
                if let imageURLsDict = space.photos {
                    thumbURL = imageURLsDict["image 1"] ?? space.category
                }
            }
            
            let customerDB = ref.child("users/\(customerUID)/chats/\(chatID)")
            let advertOwnerDB = ref.child("users/\(advertOwnerUID)/chats/\(chatID)")
            let messagesDB = Database.database().reference().child("messages/\(chatID)")

            let firstChatData = Chat(latestSender: Auth.auth().currentUser?.displayName ?? "",
                                     lastMessage: messageTextField.text!,
                                     title: advertTitleLabel.text!,
                                     chatID: chatID,
                                     location: locationLabel.text!,
                                     price: priceLabel.text!,
                                     advertOwnerUID: advertOwnerUID,
                                     customerUID: Auth.auth().currentUser?.uid ?? "",
                                     advertOwnerDisplayName: advertOwnerDisplayName,
                                     customerDisplayName: Auth.auth().currentUser?.displayName ?? "",
                                     thumbnailURL: thumbURL,
                                     messageDate: fullDateFormatter.string(from: Date()),
                                     read: "false",
                                     timestamp: (Date().timeIntervalSince1970 as Double))
            
            let existingChatData = Chat(latestSender: Auth.auth().currentUser?.displayName ?? "",
                                        lastMessage: messageTextField.text!,
                                        title: advertTitleLabel.text!,
                                        chatID: chatID,
                                        location: locationLabel.text!,
                                        price: priceLabel.text!,
                                        advertOwnerUID: advertOwnerUID,
                                        customerUID: customerUID,
                                        advertOwnerDisplayName: advertOwnerDisplayName,
                                        customerDisplayName: customerDisplayName,
                                        thumbnailURL: thumbURL,
                                        messageDate: fullDateFormatter.string(from: Date()),
                                        read: "false",
                                        timestamp: (Date().timeIntervalSince1970 as Double))
            
            let chatData = viewingExistingChat ? existingChatData.toAnyObject() : firstChatData.toAnyObject()
            let messageData = ["sender": Auth.auth().currentUser?.displayName, "message": messageTextField.text!, "messageDate": fullDateFormatter.string(from: Date())]
            
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
                                    
                                    let senderUID = Auth.auth().currentUser?.uid
                                    self.ref.child("users/\(senderUID!)/chats").child(self.chatID).updateChildValues(["read": "true"])
                                    
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
    
    @IBAction func sendMessageButtonTapped(_ sender: Any) {
        sendMessage()
    }
    
    
    @IBAction func handlePan(_ recognizer: UIPanGestureRecognizer) {
//        guard let recognizer = recognizer else { return }
        

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
        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        let dayFormatter = DateFormatter()
        let weekFormatter = DateFormatter()
        let now = Date()
        let oneHourAgo = calendar.date(byAdding: .hour, value: -1, to: now)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)
        let lastSevenDays = sevenDaysAgo!...now
        let lastHour = oneHourAgo!...now

        timeFormatter.dateFormat = "HH:mm"
        dayFormatter.dateFormat = "E, d MMM"
        weekFormatter.dateFormat = "EEEE"
        
        if message.sender == Auth.auth().currentUser?.displayName {
            let cell = senderCell
            cell.messageLabel.text = message.messageBody
            
            if let messageDate = fullDateFormatter.date(from: message.messageDate) {
                // set date to date, day and month
                cell.dateLabel.text = dayFormatter.string(from: messageDate)
                
                // if message was within the last week, just show day
                if lastSevenDays.contains(messageDate) {
                    cell.dateLabel.text = weekFormatter.string(from: messageDate)
                }
                
                // if message was today, just show time
                if calendar.isDateInToday(messageDate) {
                    cell.dateLabel.text = timeFormatter.string(from: messageDate)
   
                    // if message was within the last hour, don't show time
                    if lastHour.contains(messageDate) {
                        cell.dateLabel.text = ""
                    }
                }
            }
            
            cell.messageContainerView.layer.cornerRadius = 14
            cell.messageContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]
            return cell
        } else {
            let cell = recipientCell
            cell.messageLabel.text = message.messageBody
            
            if let messageDate = fullDateFormatter.date(from: message.messageDate) {
                // set date to day and month
                cell.dateLabel.text = dayFormatter.string(from: messageDate)
 
                // if message was within the last week, just show day
                if lastSevenDays.contains(messageDate) {
                    cell.dateLabel.text = weekFormatter.string(from: messageDate)
                }
 
                // if message was today, just show time
                if calendar.isDateInToday(messageDate) {
                    cell.dateLabel.text = timeFormatter.string(from: messageDate)
                    
                    // if message was within the last hour, don't show time
                    if lastHour.contains(messageDate) {
                        cell.dateLabel.text = ""
                    }
                }
            }
            
            cell.messageContainerView.layer.cornerRadius = 14
            cell.messageContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            
            return cell
        }
    }
}

