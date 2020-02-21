//
//  AdvertDetailsViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 06/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import Firebase
import MapKit
import NVActivityIndicatorView
import UIKit

class AdvertDetailsViewController: UIViewController, UIScrollViewDelegate {
    
    // MARK: - Outlets
    
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
    @IBOutlet var messagesButton: UIButton!
    @IBOutlet var activityView: NVActivityIndicatorView!
    @IBOutlet var directionsButton: UIButton!
    @IBOutlet var favouritesButton: UIButton!
    @IBOutlet var imageScrollViewHeight: NSLayoutConstraint!
    @IBOutlet var scrollViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var mainScrollView: UIScrollView!
    
    
    // MARK: - Properties
    
    var images = [UIImage]()
    var space: Space!
    var emailAddress: String?
    var phoneNumber: String?
    var postcode = ""
    var editingMode = false
    var arrivedFromFavourites = false
    var trashButton: UIBarButtonItem!
    var editButton: UIBarButtonItem!
    var ref = FirebaseClient.databaseRef
    var imageURLsDict: [String: String] = [:]
    var imagesDictionary: [String: UIImage] = [:]
    var thumbnail = UIImage()
    var coordinate = CLLocationCoordinate2D()
    var spaceIsFavourite: Bool {
        for favSpace in Favourites.spaces {
            if favSpace.key == space.key {
                return true
            }
        }
        return false
    }
    var hideStatusBar = true
    
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear
        
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        let navBarHeight = navigationController?.navigationBar.frame.height ?? 0
        let height = statusBarHeight + navBarHeight
        scrollViewTopConstraint.constant = -height
        
        trashButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteAdvert))
        editButton = UIBarButtonItem(image: UIImage(systemName: "pencil.tip"), style: .done, target: self, action: #selector(editAdvert))
        navigationItem.rightBarButtonItems = [trashButton, editButton]
        scrollView.delegate = self
        
        if editingMode {
            trashButton.isEnabled = true
            trashButton.tintColor = Settings.orangeTint
            editButton.isEnabled = true
            editButton.tintColor = Settings.orangeTint
            messagesButton.isEnabled = false
            messagesButton.tintColor = .gray
            favouritesButton.isHidden = true
        } else {
            trashButton.isEnabled = false
            trashButton.tintColor = .clear
            editButton.isEnabled = false
            editButton.tintColor = .clear
            messagesButton.isEnabled = true
            messagesButton.tintColor = Settings.orangeTint
            favouritesButton.isEnabled = true
            favouritesButton.tintColor = Settings.orangeTint
            
            if arrivedFromFavourites { favouritesButton.isHidden = true }
        }
        
        titleLabel.text = space.title.uppercased()
        priceLabel.text = "£\(space.price) \(priceRateFormatter(rate: space.priceRate))"
        locationLabel.text = formatAddress(for: space)
        postcode = space.postcode
        
        if space.photos == nil {
            imageScrollViewHeight.constant = 200
            scrollViewTopConstraint.constant = 0
            activityView.stopAnimating()
            
            let imageView = UIImageView()
            imageView.image = UIImage(named: "Logo Grey")
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 200)
            scrollView.addSubview(imageView)
            
            pageController.isHidden = true
        }
        
        if space.viewOnMap == false {
            mapView.isHidden = true
            directionsButton.isHidden = true
        }
        
        if space.email == "" {
            emailButton.isEnabled = false
            emailButton.tintColor = .gray
        } else {
            emailAddress = space.email
        }
        
        if space.phone == "" {
            phoneButton.isEnabled = false
            phoneButton.tintColor = .gray
        } else {
            phoneNumber = space.phone
        }
        
        if space.description == "" {
            descriptionTextView.isHidden = true
        } else {
            descriptionTextView.text = space.description
        }
        
        downloadFirebaseImages {
            // Add images to scrollView
            self.activityView.stopAnimating()
            var i = 0
            
            for key in self.imagesDictionary.keys.sorted() {
                guard let image = self.imagesDictionary[key] else { break }
                
                // Store thumbnail for chat if inititiated
                if key == "image 1" {
                    if let thumb = image.sd_resizedImage(with: CGSize(width: 300, height: 300), scaleMode: .aspectFit){
                        self.thumbnail = thumb
                    }
                }
                
                let imageView = UIImageView()
                imageView.image = image
                imageView.contentMode = .scaleAspectFill
                let xPosition = self.view.frame.width * CGFloat(i)
                imageView.frame = CGRect(x: xPosition, y: 0, width: self.scrollView.frame.width, height: self.scrollView.frame.height)
                
                self.scrollView.contentSize.width = self.scrollView.frame.width * CGFloat(i + 1)
                self.scrollView.addSubview(imageView)
                self.scrollView.backgroundColor = .black
                i += 1
            }
            self.pageController.numberOfPages = self.imagesDictionary.count
        }
        
        if space.postedByUser == Auth.auth().currentUser?.uid {
            messagesButton.isEnabled = false
            messagesButton.tintColor = .gray
        }
        
        directionsButton.layer.cornerRadius = 15
        directionsButton.layer.borderWidth = 1
        directionsButton.layer.borderColor = Settings.orangeTint.cgColor
        
        setLocationOnMap()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        favouritesButton.tintColor = spaceIsFavourite ? Settings.orangeTint : .white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UserDefaults.standard.removeObject(forKey: "ImagesUpdated")
    
    }
    
    
    //MARK: - Private Methods
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = scrollView.contentOffset.x / scrollView.frame.size.width
        pageController.currentPage = Int(pageIndex)
    }
    
    func downloadFirebaseImages(completion: @escaping () -> ()) {
        activityView.startAnimating()
        
        if let imageURLsDict = space.photos {
            self.imageURLsDict = imageURLsDict
            
            for key in imageURLsDict.keys.sorted()  {
                guard let value = imageURLsDict[key] else { break }
                
                DispatchQueue.global(qos: .background).async {
                    Storage.storage().reference(forURL: value).getData(maxSize: INT64_MAX) { [weak self] data, error  in
                        guard error == nil else {
                            print("error downloading: \(error?.localizedDescription ?? error.debugDescription)")
                            return
                        }
                        
                        if let data = data {
                            if let image = UIImage(data: data) {
                                self?.imagesDictionary[key] = image
                                if self?.imagesDictionary.count == imageURLsDict.count {
                                    completion()
                                }
                            }
                        }
                    }
                }
                
            }
        } else {
            activityView.stopAnimating()
        }
    }
    
    
    @objc func editAdvert() {
        if let vc = storyboard?.instantiateViewController(identifier: "PostSpaceNavVC") {
            let postSpaceVC = vc.children[0] as! PostSpaceViewController
            postSpaceVC.space = self.space
            postSpaceVC.updatingAdvert = true
            present(vc, animated: true)
        }
    }
    
    
    @objc func deleteAdvert() {
        let category = space.category
        let key = space.key
        let UID = Settings.currentUser?.uid
        let ac = UIAlertController(title: "Delete Space", message: "Are you sure you wish to permanently delete your advert?", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            
            let childUpdates = ["adverts/\(Location.userLocationCountry)/\(category)/\(UID!)-\(key)": NSNull(),
                                "users/\(UID!)/adverts/\(key)": NSNull()]
            
            self.ref.updateChildValues(childUpdates) { [weak self] error, databaseRef in
                if error != nil {
                    print(error?.localizedDescription as Any)
                    self?.showAlert(title: "Deletion Error", message: "We had an issue trying to delete your advert, please try again.")
                }
                
                self?.navigationController?.popToRootViewController(animated: true)
                if self?.imageURLsDict.count != 0 {
                    self?.deleteImagesFromFirebaseCloudStorage {
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
    
    @IBAction func favouritesButtonTapped(_ sender: Any) {
        if Auth.auth().currentUser != nil {
            let UID = Auth.auth().currentUser?.uid ?? ""
            let key = space.key
            let category = space.category
            let favouriteURL = category + "/" + key
            let newFavourite = FavouriteSpace(key: key, url: favouriteURL)
            
            if spaceIsFavourite {
                ref.child("users/\(UID)/favourites/\(key)").removeValue()
                favouritesButton.tintColor = .white
            } else {
                ref.child("users/\(UID)/favourites/\(key)").setValue(newFavourite.toDictionaryObject())
                favouritesButton.tintColor = Settings.orangeTint
            }
        } else {
            let vc = storyboard?.instantiateViewController(identifier: "SignInVC") as! SignInViewController
            present(vc, animated: true)
        }
    }
    
    
    @IBAction func messageButtonTapped(_ sender: Any) {
        if Auth.auth().currentUser != nil {
            let vc = storyboard?.instantiateViewController(identifier: "MessageVC") as! MessageViewController
            vc.space = space
            vc.thumbnail = thumbnail
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = storyboard?.instantiateViewController(identifier: "SignInVC") as! SignInViewController
            present(vc, animated: true)
        }
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
    
    
    @IBAction func directionsButtonTapped(_ sender: Any) {
        let mkPlacemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: MKPlacemark(placemark: mkPlacemark))
        mapItem.name = titleLabel.text!
        mapItem.openInMaps()
    }
}


//MARK: - Map Delegates

extension AdvertDetailsViewController: MKMapViewDelegate {
    
    func setLocationOnMap() {
        CLGeocoder().geocodeAddressString(space.city + ", " + postcode) { (placemark, error) in
            if error != nil {
                print(error?.localizedDescription as Any)
            }
            
            if let placemark = placemark?.first {
                if let coordinate = placemark.location?.coordinate {
                    self.coordinate = coordinate
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
