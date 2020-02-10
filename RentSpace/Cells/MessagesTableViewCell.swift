//
//  MessagesTableViewCell.swift
//  RentSpace
//
//  Created by Sean Williams on 05/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//
import NVActivityIndicatorView
import UIKit

class MessagesTableViewCell: UITableViewCell {
    
    @IBOutlet var customImageView: UIImageView!
    @IBOutlet var recipientLabel: UILabel!
    @IBOutlet var advertTitleLabel: UILabel!
    @IBOutlet var latestMessageLabel: UILabel!
    @IBOutlet var newMessageImageView: UIImageView!
    @IBOutlet var activityView: NVActivityIndicatorView!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        customImageView.heightEqualsWidth()
    }

}
