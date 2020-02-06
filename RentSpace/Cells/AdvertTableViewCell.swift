//
//  AdvertTableViewCell.swift
//  RentSpace
//
//  Created by Sean Williams on 04/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import NVActivityIndicatorView
import UIKit

class AdvertTableViewCell: UITableViewCell {
    
    @IBOutlet var customImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var categoryLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var activityView: NVActivityIndicatorView!
    @IBOutlet var distanceLabel: UILabel!
    
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        customImageView.heightEqualsWidth()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
