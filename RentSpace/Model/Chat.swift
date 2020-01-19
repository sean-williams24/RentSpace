//
//  Message.swift
//  RentSpace
//
//  Created by Sean Williams on 17/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import Foundation

class Chat {
    
    var sender: String
    var messageBody: String
    var title: String
    var chatID: String
    var location: String
    var price: String
    var advertOwnerUID: String
    var customerUID: String
    
    init(sender: String, lastMessage: String, title: String, chatID: String, location: String, price: String, advertOwnerUID: String, customerUID: String) {
        self.sender = sender
        self.messageBody = lastMessage
        self.title = title
        self.chatID = chatID
        self.location = location
        self.price = price
        self.advertOwnerUID = advertOwnerUID
        self.customerUID = customerUID
    }
}
