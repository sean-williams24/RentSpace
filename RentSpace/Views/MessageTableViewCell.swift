//
//  MessageTableViewCell.swift
//  RentSpace
//
//  Created by Sean Williams on 20/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//
import Foundation
import UIKit

class MessageTableViewCell: UITableViewCell {

    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var messageContainerView: UIView!
    @IBOutlet var messageWidthConsraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        messageContainerView.layer.cornerRadius = 8
        messageWidthConsraint.constant = self.frame.width - 100
    }
}


