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
    
    init(sender: String, messageBody: String, title: String, chatID: String) {
        self.sender = sender
        self.messageBody = messageBody
        self.title = title
        self.chatID = chatID
    }
}
