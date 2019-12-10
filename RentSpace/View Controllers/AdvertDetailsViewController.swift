//
//  AdvertDetailsViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 06/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import Firebase
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
    var advertSnapshot: DataSnapshot!
    var advert: [String : Any] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        advert = advertSnapshot.value as! [String : Any]
        
        titleLabel.text = (advert[Advert.title] as! String)
        priceLabel.text = advert[Advert.price] as? String
        descriptionTextView.text = advert[Advert.description] as? String
        locationLabel.text = formatAddress(for: advert)

        if let imageURLsDict = advert[Advert.photos] as? [String : String] {
            print(imageURLsDict.count)
            
            // TODO: - LOOP THROUGH IMAGE URLS FROM 0..IMAGEURLS.COUNT ANDDING THE INDEX TO THE DICTIONAY VALUE
        }
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
