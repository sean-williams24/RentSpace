//
//  PhotoCollectionViewCell.swift
//  RentSpace
//
//  Created by Sean Williams on 27/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var cellImageView: UIImageView!
    
    override var isSelected: Bool {
        didSet {
            cellImageView.layer.borderWidth = isSelected ? 4 : 0
            if isSelected == true {
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cellImageView.layer.borderColor = UIColor.lightGray.cgColor
        isSelected = false
    }
    
}
