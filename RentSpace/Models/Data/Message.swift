//
//  Message.swift
//  RentSpace
//
//  Created by Sean Williams on 17/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import Firebase
import Foundation

class Message {
    
    var messageBody: String
    var sender: String
    var messageDate: String
    
    init?(snapshot: DataSnapshot) {
        guard
            let message = snapshot.value as? [String:String],
            let messageBody = message["message"],
            let sender = message["sender"],
            let messageDate = message["messageDate"] else { return nil}
        
        self.messageBody = messageBody
        self.sender = sender
        self.messageDate = messageDate   
    }
}
