//
//  SenderTableViewCell.swift
//  RentSpace
//
//  Created by Sean Williams on 21/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import UIKit

class SenderTableViewCell: UITableViewCell {
    
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var messageWidthConsraint: NSLayoutConstraint!
    @IBOutlet var messageContainerView: UIView!
    
    
    

    override func awakeFromNib() {
        super.awakeFromNib()
//        messageContainerView.layer.cornerRadius = 8
//        messageWidthConsraint.constant = self.frame.width - 100
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
