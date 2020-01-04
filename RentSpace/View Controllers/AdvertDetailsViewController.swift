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

class AdvertDetailsViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var descriptionTextView: UITextView!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var locationIcon: UIImageView!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var pageController: UIPageControl!
    @IBOutlet var emailButton: UIButton!
    @IBOutlet var phoneButton: UIButton!
    
    var images = [UIImage]()
    var advertSnapshot: DataSnapshot!
    var advert: [String : Any] = [:]
    var emailAddress: String?
    var phoneNumber: String?
    var postcode = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        advert = advertSnapshot.value as! [String : Any]
        
        titleLabel.text = (advert[Advert.title] as! String)
        priceLabel.text = advert[Advert.price] as? String
        locationLabel.text = formatAddress(for: advert)
        scrollView.delegate = self
        pageController.hidesForSinglePage = true
        postcode = advert[Advert.postCode] as! String
        
        if advert[Advert.photos] == nil {
            scrollView.isHidden = true
            pageController.isHidden = true
        }
        
        if advert[Advert.viewOnMap] as? Bool == false {
            mapView.isHidden = true
        }
        
        if advert[Advert.email] as? String == "" {
            emailButton.isEnabled = false
            emailButton.tintColor = .gray
        } else {
            emailAddress = (advert[Advert.email] as? String)!
        }
        
        if advert[Advert.phone] as? String == "" {
            phoneButton.isEnabled = false
            phoneButton.tintColor = .gray
        } else {
            phoneNumber = advert[Advert.phone] as? String
        }
        
        if advert[Advert.description] as? String == "" {
            descriptionTextView.isHidden = true
        } else {
            descriptionTextView.text = advert[Advert.description] as? String
        }
        
        downloadFirebaseImages {
            // Add images to scrollView
            for i in 0..<self.images.count {
                let imageView = UIImageView()
                imageView.image = self.images[i]
                imageView.contentMode = .scaleAspectFill
                let xPosition = self.view.frame.width * CGFloat(i)
                imageView.frame = CGRect(x: xPosition, y: 0, width: self.scrollView.frame.width, height: self.scrollView.frame.height)

                self.scrollView.contentSize.width = self.scrollView.frame.width * CGFloat(i + 1)
                self.scrollView.addSubview(imageView)
            }
            self.pageController.numberOfPages = self.images.count
        }
        
        setLocationOnMap()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = scrollView.contentOffset.x / scrollView.frame.size.width
        pageController.currentPage = Int(pageIndex)
    }
    
    //MARK: - Private Methods
    
    func downloadFirebaseImages(completion: @escaping () -> ()) {
        if let imageURLsDict = advert[Advert.photos] as? [String : String] {
            for i in 0..<imageURLsDict.count {
                if let imageURL = imageURLsDict["image \(i)"] {
                    Storage.storage().reference(forURL: imageURL).getData(maxSize: INT64_MAX) { (data, error) in
                        guard error == nil else {
                            print("error downloading: \(error?.localizedDescription ?? error.debugDescription)")
                            return
                        }
                        if let data = data {
                            if let image = UIImage(data: data) {
                                self.images.append(image)
                                if self.images.count == imageURLsDict.count {
                                    completion()
                                }
                            }
                        }
                    }
                }
            }
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
    
    //MARK: - Action Methods

    
    @IBAction func messageButtonTapped(_ sender: Any) {
    }
    
    @IBAction func phoneButtonTapped(_ sender: Any) {
        if phoneNumber != nil {
            if let url = URL(string: "tel:\(phoneNumber!)") {
                UIApplication.shared.open(url)
            }
        }
    }
    
    @IBAction func emailButtonTapped(_ sender: Any) {
        if emailAddress != nil {
            if let url = URL(string: "mailto:\(emailAddress!)") {
                UIApplication.shared.open(url)
            }
        }
    }
}


//MARK: - Map Delegates

extension AdvertDetailsViewController: MKMapViewDelegate {
    
    func setLocationOnMap() {
        CLGeocoder().geocodeAddressString(postcode) { (placemark, error) in
            if error != nil {
                print(error?.localizedDescription as Any)
            }

            if let placemark = placemark?.first {
                if let coordinate = placemark.location?.coordinate {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = coordinate
                    self.mapView.addAnnotation(annotation)

                    let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 3000, longitudinalMeters: 3000)
                    self.mapView.setRegion(region, animated: true)
                }
            }
        }
    }
}
