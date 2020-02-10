//
//  MySpacesTableViewCell.swift
//  RentSpace
//
//  Created by Sean Williams on 05/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//
import NVActivityIndicatorView
import UIKit

class MySpacesTableViewCell: UITableViewCell {

    @IBOutlet var customImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var categoryLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var activityView: NVActivityIndicatorView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        customImageView.heightEqualsWidth()
    }

}
