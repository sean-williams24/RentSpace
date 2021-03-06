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
    
    // MARK: - Outlets
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var advertTitleLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var messagesTableView: UITableView!
    @IBOutlet var messageTextField: UITextField!
    @IBOutlet var sendMessageButton: UIButton!
    @IBOutlet var activityView: NVActivityIndicatorView!
    @IBOutlet var loadingLabel: UILabel!
    
    
    // MARK: - Properties
    
    var messages: [Message] = []
    var space: Space!
    var ref: DatabaseReference!
    var refHandle: DatabaseHandle!
    var chatID = ""
    var customerUID = ""
    var chat: Chat!
    var viewingExistingChat = false
    var thumbnail = UIImage()
    var messageRead = "false"
    var previousMessageDate = ""
    let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss E, d MMM, yyyy"
        return formatter
    }()
    var recipientUID = ""
    var recipientHasReadAllMessages = ""
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        if let UID = Auth.auth().currentUser?.uid { customerUID = UID }
        
        // If arriving from AdvertDetailsVC, this is a new chat - create new unique chat ID using current users UID + advert key
        if !viewingExistingChat {
            chatID = customerUID + "-" + space.key
            
            let isRegisteredForRemoteNotifications = UIApplication.shared.isRegisteredForRemoteNotifications
            if !isRegisteredForRemoteNotifications {
                self.showAlert(title: "Notifications Off", message: "\nWithout notifications turned on you may miss messages. Notifications can be turned on in the Settings App.")
            }
        }
        
        configureUI()
        listenForNewMessages()
        scrollToBottomMessage()
        dismissKeyboardOnViewTap()
        subscribeToKeyboardNotifications()
        checkIfRecipientHasUnreadMessages {}
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateTableContentInset()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if refHandle != nil {
            ref.child("messages/\(chatID)").removeObserver(withHandle: refHandle)
        }
        unsubscribeFromKeyboardNotifications()
    }
    
    
    // MARK: - Helper Methods
    
    fileprivate func checkIfRecipientHasUnreadMessages(completion: @escaping() -> Void) {
        var advertOwnerUID = ""
        if viewingExistingChat {
            advertOwnerUID = chat.advertOwnerUID
        } else {
            // If this is a new chat, set advertOwner details from advert object
            advertOwnerUID = space.postedByUser
        }
        
        // Before sending messages check to see if recipient already has unread message from this chat
        recipientUID = Auth.auth().currentUser?.uid == advertOwnerUID ? self.customerUID : advertOwnerUID
        self.ref.child("users/\(recipientUID)/chats").child(self.chatID).observeSingleEvent(of: .value) { (chatSnapshot) in
            let value = chatSnapshot.value as? NSDictionary
            self.recipientHasReadAllMessages = value?["read"] as? String ?? "true"
            completion()
        }
    }
    
    
    // Pin new messages(rows) to bottom of tableView
    func updateTableContentInset() {
        let numRows = tableView(self.messagesTableView, numberOfRowsInSection: 0)
        // Set contentInsetTop to height of tableview
        var contentInsetTop = self.messagesTableView.bounds.size.height
        for i in 0..<numRows {
            // Iterate through all rows getting CGRect for each
            let rowRect = self.messagesTableView.rectForRow(at: IndexPath(item: i, section: 0))
            // Subtract each rows height from contentInsetTop
            contentInsetTop -= rowRect.size.height
            if contentInsetTop <= 0 {
                contentInsetTop = 0
            }
        }
        self.messagesTableView.contentInset = UIEdgeInsets(top: contentInsetTop,left: 0,bottom: 0,right: 0)
    }
    
    
    fileprivate func configureUI() {
        messageTextField.layer.cornerRadius = 20
        messageTextField.layer.borderWidth = 1
        messageTextField.layer.borderColor = UIColor.darkGray.cgColor
        addLeftPadding(for: messageTextField, placeholderText: "Message...", placeholderColour: .gray)
        
        if viewingExistingChat {
            advertTitleLabel.text = chat.title
            locationLabel.text = chat.location
            priceLabel.text = chat.price
            self.showLoadingUI(true, for: self.activityView, label: self.loadingLabel, text: "Loading Messages...")
        } else {
            // New chat initiated
            advertTitleLabel.text = space.title
            locationLabel.text = Formatting.formatAddress(for: space)
            priceLabel.text = "\(space.price) \(Formatting.priceRateFormatter(rate: space.priceRate))"
        }
        
        if thumbnail.size.height == 0.0 {
            if let image = UIImage(named: "RentSpace Icon Small Black BG") {
                thumbnail = image
            }
        }
        imageView.image = renderCirlularImage(for: thumbnail)
    }
    
    
    fileprivate func listenForNewMessages() {
        refHandle = ref.child("messages/\(chatID)").observe(.value, with: { (dataSnapshot) in
            var newMessages: [Message] = []
            
            for child in dataSnapshot.children {
                if let messageSnapshot = child as? DataSnapshot {
                    if let message = Message(snapshot: messageSnapshot) {
                        newMessages.append(message)
                        
                        // If sender of message is not signed in user
                        let currentUserUID = Auth.auth().currentUser?.uid ?? ""
                        if message.sender != currentUserUID {
                            // Update message as read
                            let userChatsDB = self.ref.child("users/\(currentUserUID)/chats")
                            userChatsDB.child(self.chatID).updateChildValues(["read": "true"])
                        }
                    }
                }
            }
            self.messages = newMessages
            self.showLoadingUI(false, for: self.activityView, label: self.loadingLabel, text: "Loading Messages...")
            self.messagesTableView.reloadData()
            self.scrollToBottomMessage()
        })
    }
    
    
    func scrollToBottomMessage() {
        if messages.count == 0 { return }
        let bottomMessageIndex = IndexPath(row: messagesTableView.numberOfRows(inSection: 0) - 1, section: 0)
        messagesTableView.scrollToRow(at: bottomMessageIndex, at: .bottom, animated: true)
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
            let messagesDB = ref.child("messages/\(chatID)")
            
            let firstChatData = Chat(latestSender: Auth.auth().currentUser?.uid ?? "",
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
            
            let existingChatData = Chat(latestSender: Auth.auth().currentUser?.uid ?? "",
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
            let messageData = ["sender": Auth.auth().currentUser?.uid, "message": messageTextField.text!, "messageDate": fullDateFormatter.string(from: Date())]
            
            self.checkIfRecipientHasUnreadMessages {
                // Upload message to advert owners chat path and customers chats pathes, as well as messages path.
                advertOwnerDB.setValue(chatData) { (recipientError, recipientRef) in
                    if recipientError != nil {
                        print("Error uploading to recipient DB: \(recipientError?.localizedDescription as Any)")
                        self.showAlert(title: "Oh Dear", message: "Something went wrong, please try sending the message again.")
                        return
                    } else {
                        
                        // -- PUSH NOTIFICATIONS -- //
                        // Recipient has successfully received message - send push notification
                        // If logged in user is advert owner, message recipient is customer, if logged in user is customer, message recipient would be advert owner
                        let senderUsername = Auth.auth().currentUser?.displayName ?? "New Message"
                        let recipientUID = Auth.auth().currentUser?.uid == advertOwnerUID ? self.customerUID : advertOwnerUID
                        
                        // Get recipients messaging token and badge count from database and send push notification
                        self.ref.child("users/\(recipientUID)").child("tokens").observeSingleEvent(of: .value) { (fcmSnapshot) in
                            let value = fcmSnapshot.value as? NSDictionary
                            let token = value?["fcmToken"] as? String ?? "No Token"
                            var badgeCount = value?["badgeCount"] as? Int ?? 1
                            
                            if self.recipientHasReadAllMessages == "true" {
                                // update recipients badge count on database
                                badgeCount += 1
                                self.ref.child("users/\(recipientUID)/tokens/badgeCount").setValue(badgeCount)
                                self.recipientHasReadAllMessages = "false"
                            } else {
                                self.ref.child("users/\(recipientUID)/tokens/badgeCount").setValue(badgeCount)
                            }
                            
                            let sender = PushNotificationSender()
                            sender.sendPushNotification(to: token, title: senderUsername, body: self.messageTextField.text ?? "", badgeCount: badgeCount)
                        }
                        
                        // Upload message to customers chats path, as well as messages path.
                        customerDB.setValue(chatData) { (error, chatRef) in
                            if error != nil {
                                print("Error sending message: \(error?.localizedDescription as Any)")
                                self.showAlert(title: "Oh Dear", message: "Something went wrong, please try sending the message again.")
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
    }
    
    
    // MARK: - Action Methods    
    
    @IBAction func sendMessageButtonTapped(_ sender: Any) {
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
        
        if message.sender == Auth.auth().currentUser?.uid {
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
                        cell.dateLabel.isHidden = true
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
                        cell.dateLabel.isHidden = true
                    }
                }
            }
            
            cell.messageContainerView.layer.cornerRadius = 14
            cell.messageContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            return cell
        }
    }
}
