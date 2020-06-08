//
//  Message.swift
//  RentSpace
//
//  Created by Sean Williams on 17/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import Firebase
import Foundation

class Chat {
    
    var latestSender: String
    var messageBody: String
    var title: String
    var chatID: String
    var location: String
    var price: String
    var advertOwnerUID: String
    var customerUID: String
    var advertOwnerDisplayName: String
    var customerDisplayName: String
    var thumbnailURL: String
    var messageDate: String
    var read: String
    var timestamp: Double
    
    init(latestSender: String, lastMessage: String, title: String, chatID: String, location: String, price: String, advertOwnerUID: String, customerUID: String, advertOwnerDisplayName: String, customerDisplayName: String, thumbnailURL: String, messageDate: String, read: String, timestamp: Double) {
        self.latestSender = latestSender
        self.messageBody = lastMessage
        self.title = title
        self.chatID = chatID
        self.location = location
        self.price = price
        self.advertOwnerUID = advertOwnerUID
        self.customerUID = customerUID
        self.advertOwnerDisplayName = advertOwnerDisplayName
        self.customerDisplayName = customerDisplayName
        self.thumbnailURL = thumbnailURL
        self.messageDate = messageDate
        self.read = read
        self.timestamp = timestamp
    }
    
    init?(snapshot: DataSnapshot) {
        guard
            let chat = snapshot.value as? [String: AnyObject],
            let latestSender = chat["latestSender"] as? String,
            let title = chat["title"] as? String,
            let location = chat["location"] as? String,
            let price = chat["price"] as? String,
            let lastMessage = chat["lastMessage"] as? String,
            let chatID = chat["chatID"] as? String,
            let advertOwnerUID = chat["advertOwnerUID"] as? String,
            let customerUID = chat["customerUID"] as? String,
            let advertOwnerDisplayName = chat["advertOwnerDisplayName"] as? String,
            let customerDisplayName = chat["customerDisplayName"] as? String,
            let thumbnailURL = chat["thumbnailURL"] as? String,
            let messageDate = chat["messageDate"] as? String,
            let read = chat["read"] as? String,
            let timestamp = chat["timestamp"] as? Double? else { return nil }
        
        self.latestSender = latestSender
        self.messageBody = lastMessage
        self.title = title
        self.chatID = chatID
        self.location = location
        self.price = price
        self.advertOwnerUID = advertOwnerUID
        self.customerUID = customerUID
        self.advertOwnerDisplayName = advertOwnerDisplayName
        self.customerDisplayName = customerDisplayName
        self.thumbnailURL = thumbnailURL
        self.messageDate = messageDate
        self.read = read
        self.timestamp = timestamp ?? 0
    }
    
    func toAnyObject() -> Any {
        return [
            "latestSender": latestSender,
            "lastMessage": messageBody,
            "title": title,
            "chatID": chatID,
            "location": location,
            "price": price,
            "advertOwnerUID": advertOwnerUID,
            "customerUID": customerUID,
            "advertOwnerDisplayName": advertOwnerDisplayName,
            "customerDisplayName": customerDisplayName,
            "thumbnailURL": thumbnailURL,
            "messageDate": messageDate,
            "read": read,
            "timestamp": timestamp
        ]
    }
}
