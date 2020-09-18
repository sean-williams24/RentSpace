//
//  MySpacesTableViewCell.swift
//  RentSpace
//
//  Created by Sean Williams on 05/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import Firebase
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
    
    
    var viewingFavourites: Bool!
    var tableView: UITableView!
    var indexPath: IndexPath!
    var space: Space! {
        didSet {
            if viewingFavourites {
                backgroundColor = .darkGray
                layer.borderWidth = 0
            } else {
                backgroundColor = Settings.flipsideBlackColour
                layer.borderColor = UIColor.black.cgColor
            }
            
            customImageView.image = nil
            customImageView.alpha = 1
            activityView.startAnimating()
            customImageView.layer.borderColor = Settings.flipsideBlackColour.cgColor
            customImageView.layer.borderWidth = 1
            customImageView.layer.cornerRadius = 10
            titleLabel.text = space?.title.uppercased()
            descriptionLabel.text = space?.description
            categoryLabel.text = space?.category
            //            locationLabel.text = formatAddress(for: space)
            //            priceLabel.text = "\(space.price) \(priceRateFormatter(rate: space.priceRate))"
            
            if let imageURLsDict = space?.photos {
                if let imageURL = imageURLsDict["image 1"] {
                    
                    DispatchQueue.global(qos: .background).async {
                        Storage.storage().reference(forURL: imageURL).getData(maxSize: INT64_MAX) { (data, error) in
                            guard error == nil else {
                                print("error downloading: \(error?.localizedDescription ?? error.debugDescription)")
                                return
                            }
                            let cellImage = UIImage.init(data: data!, scale: 0.1)
                            
                            // Check to see if cell is still on screen, if so update cell
                            if self == self.tableView.cellForRow(at: self.indexPath) {
                                DispatchQueue.main.async {
                                    self.activityView.stopAnimating()
                                    self.customImageView.transform = CGAffineTransform(scaleX: 1, y: 1)
                                    self.customImageView.contentMode = .scaleAspectFill
                                    self.customImageView?.image = cellImage
                                    self.setNeedsLayout()
                                }
                            }
                        }
                    }
                }
            } else {
                activityView.stopAnimating()
                
                if space?.category == "Art Studio" {
                    
                    // Scale Art studio image down to match SFSymbol icons and add another view to get matching image border
                    let view = UIView()
                    view.frame = CGRect(x: 10, y: 10, width: 130, height: 130)
                    view.layer.borderColor = UIColor.darkGray.cgColor
                    view.layer.borderWidth = 1
                    view.layer.cornerRadius = 10
                    addSubview(view)
                    
                    if let image = UIImage(named: space?.category ?? "Desk Space") {
                        customImageView.image = image.withRenderingMode(.alwaysTemplate)
                    }
                    
                    customImageView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                    customImageView.contentMode = .scaleAspectFit
                    customImageView.layer.borderWidth = 0
                    
                } else {
                    var sfSymbol = ""
                    switch space?.category {
                    case "Photography Studio": sfSymbol = "camera"
                    case "Music Studio": sfSymbol = "music.mic"
                    case "Desk Space": sfSymbol = "studentdesk"
                    default:
                        sfSymbol = "camera"
                    }
                    
                    if #available(iOS 13.0, *) {
                        customImageView.image = Formatting.renderTemplateImage(imageName: sfSymbol)
                    } else {
                        customImageView.image = Formatting.renderTemplateImage(imageName: space.category)
                    }
                    
                    customImageView.transform = CGAffineTransform(scaleX: 1, y: 1)
                    customImageView.contentMode = .scaleAspectFit
                    customImageView.layer.borderWidth = 1
                }
                customImageView.tintColor = UIColor.darkGray
                customImageView.layer.borderColor = UIColor.darkGray.cgColor
                customImageView.alpha = 0.7
                
            }
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        customImageView.heightEqualsWidth()
        
    }
    
}
