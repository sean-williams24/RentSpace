//
//  Message.swift
//  RentSpace
//
//  Created by Sean Williams on 17/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

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
    
    init(latestSender: String, lastMessage: String, title: String, chatID: String, location: String, price: String, advertOwnerUID: String, customerUID: String, advertOwnerDisplayName: String, customerDisplayName: String, thumbnailURL: String, messageDate: String, read: String) {
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
    }
}
