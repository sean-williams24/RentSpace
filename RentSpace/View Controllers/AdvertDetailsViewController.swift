//
//  AdvertDetailsViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 06/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import MapKit
import UIKit

class AdvertDetailsViewController: UIViewController {

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var descriptionTextView: UITextView!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var locationIcon: UIImageView!
    @IBOutlet var mapView: MKMapView!
    
    var images = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        images = [#imageLiteral(resourceName: "Desk Space"),#imageLiteral(resourceName: "Music Studio")]
        
        for i in 0..<images.count {
            let imageView = UIImageView()
            imageView.image = images[i]
            imageView.contentMode = .scaleAspectFit
            let xPosition = view.frame.width * CGFloat(i)
            imageView.frame = CGRect(x: xPosition, y: 0, width: self.scrollView.frame.width, height: self.scrollView.frame.height)
            
            scrollView.contentSize.width = scrollView.frame.width * CGFloat(i + 1)
            scrollView.addSubview(imageView)
        }

    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func messageButtonTapped(_ sender: Any) {
    }
    
    @IBAction func phoneButtonTapped(_ sender: Any) {
    }
    
    @IBAction func emailButtonTapped(_ sender: Any) {
    }
    
    
}
