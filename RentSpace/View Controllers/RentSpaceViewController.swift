//
//  RentSpaceViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 27/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import Firebase
import MapKit
import NVActivityIndicatorView
import UIKit

protocol UpdateSearchLocationDelegate {
    func didUpdateLocation(town: String, city: String, county: String, postcode: String, country: String, location: CLLocation, distance: Double)
    func didUpdate(distance: Double)
}

class RentSpaceViewController: UIViewController {

    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var activityView: NVActivityIndicatorView!
    @IBOutlet var loadingLabel: UILabel!
    
    var ref: DatabaseReference!
    var storageRef: StorageReference!
    fileprivate var _refHandle: DatabaseHandle!
    
    var filteredAdverts: [DataSnapshot] = []
    var array: [DataSnapshot]!
    var chosenAdvert: DataSnapshot!
    var chosenCategory = ""
    var location = ""
    var searchAreaButtonTitle = ""
    var rightBarButton = UIBarButtonItem()
    var searchDistance = 20.00
    var distances: [Double] = []
    
    
    // MARK: - Life Cycle

    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        
        // Set title of location button to saved user location. If none then users current location.
        
        if let UDTitle = UserDefaults.standard.string(forKey: "Location") {
            searchAreaButtonTitle = UDTitle.uppercased()
        } else {
            if let town = Constants.userLocationAddress?.subLocality {
                searchAreaButtonTitle = town.uppercased()
                if town == "" {
                    searchAreaButtonTitle = Constants.userLocationAddress?.city ?? "Search Area"
                }
            } else if let city = Constants.userLocationAddress?.city {
                searchAreaButtonTitle = city.uppercased()
            } else if let postcode = Constants.userLocationAddress?.postalCode {
                searchAreaButtonTitle = postcode.uppercased()
            }
        }
        
        rightBarButton = UIBarButtonItem(title: searchAreaButtonTitle, style: .done, target: self, action: #selector(setSearchRadius))
        navigationItem.rightBarButtonItem = rightBarButton
        
        storageRef = Storage.storage().reference()

        if UserDefaults.standard.double(forKey: "Distance") != 0.0 {
            Constants.searchDistance = UserDefaults.standard.double(forKey: "Distance")
        } 
        
        if Constants.savedLocationExists == true {
            getAdverts(for: Constants.customCLLocation, within: Constants.searchDistance)
        } else {
            getAdverts(for: Constants.userCLLocation, within: Constants.searchDistance)
        }
        

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.filteredAdverts.isEmpty {
                UIView.animate(withDuration: 1) {
                    self.loadingLabel.alpha = 0
                    self.loadingLabel.text = "No spaces were found, try expanding your search radius"
                    UIView.animate(withDuration: 3) {
                        self.loadingLabel.alpha = 1
                    }
                }
            }
        }
    }
    

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let location = rightBarButton.title
        UserDefaults.standard.set(location, forKey: "Location")
    }
    // MARK: - Private Methods
    

    fileprivate func startCellLoadingActivityView() {
        let indexPath = IndexPath(row: 0, section: self.tableView.numberOfSections - 1)
        guard let cell = self.tableView.cellForRow(at: indexPath) as? AdvertTableViewCell else { return }
        cell.activityView.startAnimating()
    }
    
    func getAdverts(for userLocation: CLLocation, within setMiles: Double) {
        self.showLoadingUI(true, for: self.activityView, label: self.loadingLabel)
        
        filteredAdverts.removeAll()
        distances.removeAll()
        ref = Database.database().reference()
                
        if setMiles == 310.0 {
            // Nationwide results, i.e. all adverts
            _refHandle = ref.child("adverts/\(location)/\(chosenCategory)").observe(.value, with: { (snapshot) in
                self.filteredAdverts = []
                for child in snapshot.children {
                    if let advertSnapshot = child as? DataSnapshot {
                        self.filteredAdverts.append(advertSnapshot)
                    }
                    self.showLoadingUI(false, for: self.activityView, label: self.loadingLabel)
                    self.tableView.reloadData()
                    self.startCellLoadingActivityView()
                }
            })
        } else {
            _refHandle = ref.child("adverts/\(location)/\(chosenCategory)").observe(.value, with: { (snapshot) in
                self.filteredAdverts = []
                self.tableView.reloadData()
                for child in snapshot.children {
                    if let advertSnapshot = child as? DataSnapshot {
                        let advert = advertSnapshot.value as? NSDictionary ?? [:]
                        let postcode = advert[Advert.postCode] as! String
                        
                        // Get distance of advert location from users chosen location and add to table if within search radius
                        CLGeocoder().geocodeAddressString(postcode) { (placemark, error) in
                            if let placemark = placemark?.first {
                                let advertLocation = placemark.location
                                if let distance = advertLocation?.distance(from: userLocation) {
                                    let distanceInMiles = distance / 1609.344
                                    
                                    if distanceInMiles < setMiles {
                                        print("Set Miles: \(setMiles)")
                                        print("Distance: \(distanceInMiles)")
                                        self.showLoadingUI(false, for: self.activityView, label: self.loadingLabel)
                                        self.filteredAdverts.append(advertSnapshot)
                                        self.tableView.reloadData()
                                        self.startCellLoadingActivityView()
                                    }
                                }
                            }
                        }
                    }
                }
            })
        }
    }
    
    deinit {
        ref.child("adverts/\(location)/\(chosenCategory)").removeObserver(withHandle: _refHandle)
    }

    
    @objc func setSearchRadius() {
        
        let vc = storyboard?.instantiateViewController(identifier: "SearchRadiusVC") as! SearchRadiusViewController
//        let postCode = Constants.userLocationAddress?.postalCode
//        vc.currentLocation = "\(rightBarButton.title ?? "Select Location"))"
        vc.delegate = self
//        vc.searchDistance = searchDistance
        show(vc, sender: self)
        
    }
    

}

// MARK: - TableView Delegates & Datasource


extension RentSpaceViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return filteredAdverts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 3
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Advert Cell", for: indexPath) as! AdvertTableViewCell
//        cell.layer.cornerRadius = 8
        cell.layer.borderWidth = 1
        
        let advertSnapshot = filteredAdverts[indexPath.section]
        let advert = advertSnapshot.value as! [String : Any]
                
        // Populate cell content from downloaded advert data from Firebase
        let title = advert[Advert.title] as? String
        cell.titleLabel.text = title?.uppercased()
        cell.descriptionLabel.text = advert[Advert.description] as? String
        cell.categoryLabel.text = advert[Advert.category] as? String
        cell.locationLabel.text = formatAddress(for: advert)

        if let price = advert[Advert.price] as? String, let priceRate = advert[Advert.priceRate] as? String {
            cell.priceLabel.text = "£\(price) \(priceRateFormatter(rate: priceRate))"
        }
        
        if let imageURLsDict = advert[Advert.photos] as? [String : String] {
            if let imageURL = imageURLsDict["image 1"] {
            
                Storage.storage().reference(forURL: imageURL).getData(maxSize: INT64_MAX) { (data, error) in
                    guard error == nil else {
                        print("error downloading: \(error?.localizedDescription ?? error.debugDescription)")
                        return
                    }
                    let cellImage = UIImage.init(data: data!, scale: 0.1)
                    
                    // Check to see if cell is still on screen, if so update cell
                    if cell == tableView.cellForRow(at: indexPath) {
                        DispatchQueue.main.async {
                            cell.activityView.stopAnimating()
                            cell.customImageView.alpha = 1
                            cell.customImageView?.image = cellImage
                            cell.setNeedsLayout()
                        }
                    }
                }
            }
        } else {
            cell.customImageView.image = UIImage(named: "003-desk")
            cell.customImageView.alpha = 1
            cell.activityView.stopAnimating()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(identifier: "AdvertDetailsVC") as! AdvertDetailsViewController
        vc.advertSnapshot = filteredAdverts[indexPath.section]
        show(vc, sender: self)
    }
}

extension RentSpaceViewController: UpdateSearchLocationDelegate {
    
    func didUpdate(distance: Double) {
        if Constants.savedLocationExists == true {
            getAdverts(for: Constants.customCLLocation, within: distance)
        } else {
            getAdverts(for: Constants.userCLLocation, within: distance)
        }
        
        loadingLabel.isHidden = false
        loadingLabel.text = "Finding Spaces..."
    }

    
    func didUpdateLocation(town: String, city: String, county: String, postcode: String, country: String, location: CLLocation, distance: Double) {
        getAdverts(for: location, within: distance)
        rightBarButton.title = town
        if town == "" {
            rightBarButton.title = city.uppercased()
            if city == "" {
                rightBarButton.title = county.uppercased()
                if county == "" {
                    rightBarButton.title = country.uppercased()
                    if country == "" {
                        rightBarButton.title = postcode.uppercased()
                    }
                }
            }
        }
        UserDefaults.standard.set(rightBarButton.title, forKey: "Location")
        UserDefaults.standard.set(postcode, forKey: "LocationPostcode")
    }
}
