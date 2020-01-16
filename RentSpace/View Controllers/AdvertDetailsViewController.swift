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
    var advert: [String: Any] = [:]
    var emailAddress: String?
    var phoneNumber: String?
    var postcode = ""
    var editingMode = false
    var trashButton: UIBarButtonItem!
    var editButton: UIBarButtonItem!
    var ref: DatabaseReference!
    var imageURLsDict: [String: String] = [:]
    var imagesDictionary: [String: UIImage] = [:]
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        advert = advertSnapshot.value as! [String : Any]
        
        trashButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteAdvert))
        editButton = UIBarButtonItem(image: UIImage(systemName: "pencil.tip"), style: .done, target: self, action: #selector(editAdvert))
        navigationItem.rightBarButtonItems = [trashButton, editButton]
        
        if editingMode {
            trashButton.isEnabled = true
            trashButton.tintColor = .systemPurple
            editButton.isEnabled = true
            editButton.tintColor = .systemPurple
        } else {
            trashButton.isEnabled = false
            trashButton.tintColor = .clear
            editButton.isEnabled = false
            editButton.tintColor = .clear
        }
        
        titleLabel.text = (advert[Advert.title] as! String)
        if let price = advert[Advert.price] as? String, let priceRate = advert[Advert.priceRate] as? String {
            priceLabel.text = "£\(price) \(priceRateFormatter(rate: priceRate))"
        }
        
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
            print(self.imagesDictionary)
            var i = 0
            
            for key in self.imagesDictionary.keys.sorted() {
                guard let image = self.imagesDictionary[key] else { break }
                let imageView = UIImageView()
                imageView.image = image
                imageView.contentMode = .scaleAspectFill
                let xPosition = self.view.frame.width * CGFloat(i)
                imageView.frame = CGRect(x: xPosition, y: 0, width: self.scrollView.frame.width, height: self.scrollView.frame.height)
                
                self.scrollView.contentSize.width = self.scrollView.frame.width * CGFloat(i + 1)
                self.scrollView.addSubview(imageView)
                i += 1
            }
            self.pageController.numberOfPages = self.imagesDictionary.count
        }
        
        setLocationOnMap()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UserDefaults.standard.removeObject(forKey: "ImagesUpdated")
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = scrollView.contentOffset.x / scrollView.frame.size.width
        pageController.currentPage = Int(pageIndex)
    }
    
    
    
    @objc func editAdvert() {
        if let vc = storyboard?.instantiateViewController(identifier: "PostSpaceNavVC") {
            let postSpaceVC = vc.children[0] as! PostSpaceViewController
            postSpaceVC.advert = self.advert
            postSpaceVC.updatingAdvert = true
            postSpaceVC.advertSnapshot = advertSnapshot
            present(vc, animated: true)
        }
    }
    
    
    @objc func deleteAdvert() {
        let category = advert[Advert.category] as! String
        let key = advertSnapshot.key
        let UID = Settings.currentUser?.uid
        let ac = UIAlertController(title: "Delete Advert", message: "Are you sure you wish to permanently delete your advert?", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            
            let childUpdates = ["adverts/\(Constants.userLocationCountry)/\(category)/\(UID!)-\(key)": NSNull(),
                                "users/\(UID!)/adverts/\(key)": NSNull()]
            
            self.ref.updateChildValues(childUpdates) { (error, databaseRef) in
                if error != nil {
                    print(error?.localizedDescription as Any)
                }
                print("Deletion completion")
                self.navigationController?.popToRootViewController(animated: true)
                if self.imageURLsDict.count != 0 {
                    self.deleteImagesFromFirebaseCloudStorage {
                        print("Images deleted from Cloud Firestore")
                    }
                }
            }
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .default))
        
        present(ac, animated: true)
    }
    
    
    func deleteImagesFromFirebaseCloudStorage(completion: @escaping() -> ()) {
        let storage = Storage.storage()
        var deletedImagesCount = 0
        for (_, imageURL) in imageURLsDict {
            let storRef = storage.reference(forURL: imageURL)
            storRef.delete { (error) in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    deletedImagesCount += 1
                    print("Image Deleted: \(deletedImagesCount)")
                    if deletedImagesCount == self.imageURLsDict.count {
                        completion()
                    }
                }
            }
        }
    }
    
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

extension AdvertDetailsViewController {
    //MARK: - Private Methods
    
    // refactor this and cloud delete to Firebase client class
    func downloadFirebaseImages(completion: @escaping () -> ()) {
        if let imageURLsDict = advert[Advert.photos] as? [String : String] {
            self.imageURLsDict = imageURLsDict
            
            for key in imageURLsDict.keys.sorted()  {
                guard let value = imageURLsDict[key] else { break }
                
                Storage.storage().reference(forURL: value).getData(maxSize: INT64_MAX) { (data, error) in
                    guard error == nil else {
                        print("error downloading: \(error?.localizedDescription ?? error.debugDescription)")
                        return
                    }
                    
                    if let data = data {
                        if let image = UIImage(data: data) {
                            self.imagesDictionary[key] = image
                            if self.imagesDictionary.count == imageURLsDict.count {
                                completion()
                            }
                        }
                    }
                }
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
    
    
    //    func downloadFirebaseImages(completion: @escaping () -> ()) {
    //        if let imageURLsDict = advert[Advert.photos] as? [String : String] {
    //            self.imageURLsDict = imageURLsDict
    //
    //            for key in imageURLsDict.keys.sorted()  {
    //                guard let value = imageURLsDict[key] else { break }
    //                print("\(key), \(value)")
    //
    //                Storage.storage().reference(forURL: value).getData(maxSize: INT64_MAX) { (data, error) in
    //                    guard error == nil else {
    //                        print("error downloading: \(error?.localizedDescription ?? error.debugDescription)")
    //                        return
    //                    }
    //
    //                    if let data = data {
    //                        if let image = UIImage(data: data) {
    //                            self.images.append(image)
    //                            print("KEY: \(key)")
    //                            print("VALUE: \(value)")
    //                            self.imagesDictionary[key] = image
    //
    //                            if self.images.count == imageURLsDict.count {
    //                                completion()
    //                            }
    //                        }
    //                    }
    //                }
    //        }
    //    }
    //    }
}
