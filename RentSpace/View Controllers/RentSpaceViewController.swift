//
//  RentSpaceViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 27/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import Firebase
import MapKit
import UIKit

protocol UpdateSearchLocationDelegate {
    func didUpdateLocation(town: String, city: String, county: String, postcode: String, country: String, location: CLLocation, distance: Double)
}

class RentSpaceViewController: UIViewController{

    
    @IBOutlet var tableView: UITableView!
    
    var ref: DatabaseReference!
    var storageRef: StorageReference!
    fileprivate var _refHandle: DatabaseHandle!
    
//    var adverts: [DataSnapshot] = []
    var filteredAdverts: [DataSnapshot] = []
    var chosenAdvert: DataSnapshot!
    var chosenCategory = ""
    var location = ""
    var searchAreaButtonTitle = ""
    var rightBarButton = UIBarButtonItem()
    var searchDistance = 10.00
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let town = Constants.userLocationAddress?.subLocality {
            searchAreaButtonTitle = town
            if town == "" {
                searchAreaButtonTitle = Constants.userLocationAddress?.city ?? "Search Area"
            }
        } else if let city = Constants.userLocationAddress?.city {
            searchAreaButtonTitle = city
        } else if let postcode = Constants.userLocationAddress?.postalCode {
            searchAreaButtonTitle = postcode
        }

        
        rightBarButton = UIBarButtonItem(title: searchAreaButtonTitle, style: .done, target: self, action: #selector(setSearchRadius))
        navigationItem.rightBarButtonItem = rightBarButton
        
        storageRef = Storage.storage().reference()
//        configureDatabase()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       // tableView.reloadData()
//        print(Constants.searchDistance)
        

    }

    
    // MARK: - Private Methods
    

    
    // MARK: - Config

    func configureDatabase(for userLocation: CLLocation, within setMiles: Double) {
        filteredAdverts.removeAll()
        ref = Database.database().reference()
        
        _refHandle = ref.child("adverts/\(location)/\(chosenCategory)").observe(.childAdded, with: { (snapshot) in
            let advert = snapshot.value as? NSDictionary ?? [:]
            let postcode = advert[Advert.postCode] as! String
            
            // Get distance of advert location from users chosen location and add to table if within search radius
            CLGeocoder().geocodeAddressString(postcode) { (placemark, error) in
                if let placemark = placemark?.first {
                    let advertLocation = placemark.location
                    if let distance = advertLocation?.distance(from: userLocation) {
                        let distanceMiles = distance / 1609.344

                        if distanceMiles < setMiles {
                            self.filteredAdverts.append(snapshot)
                            self.tableView.reloadData()
//                            self.tableView.insertSections(IndexSet(integer: self.adverts.count - 1), with: .automatic)
                        }
                    }
                }
            }
        })
    }
    
    deinit {
        ref.child("adverts/\(location)/\(chosenCategory)").removeObserver(withHandle: _refHandle)
    }
    
    //MARK: - Private Methods
    
    @objc func setSearchRadius() {
        
        let vc = storyboard?.instantiateViewController(identifier: "SearchRadiusVC") as! SearchRadiusViewController
        let postCode = Constants.userLocationAddress?.postalCode
        vc.currentLocation = "\(rightBarButton.title ?? "Select Location"), \(postCode ?? "")"
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
        return 5
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Advert Cell", for: indexPath) as! AdvertTableViewCell
        cell.layer.cornerRadius = 8
        cell.layer.borderWidth = 1
        
        let advertSnapshot = filteredAdverts[indexPath.section]
        let advert = advertSnapshot.value as! [String : Any]
        
        // Populate cell content from downloaded advert data from Firebase
        let title = advert[Advert.title] as? String
        cell.titleLabel.text = title?.uppercased()
        cell.descriptionLabel.text = advert[Advert.description] as? String
        cell.categoryLabel.text = advert[Advert.category] as? String
        cell.locationLabel.text = formatAddress(for: advert)
        cell.priceLabel.text = advert[Advert.price] as? String
        if let imageURLsDict = advert[Advert.photos] as? [String : String] {
            if let imageURL = imageURLsDict["image 0"] {
            
                Storage.storage().reference(forURL: imageURL).getData(maxSize: INT64_MAX) { (data, error) in
                    guard error == nil else {
                        print("error downloading: \(error?.localizedDescription ?? error.debugDescription)")
                        return
                    }
                    let cellImage = UIImage.init(data: data!, scale: 0.1)
                    
                    // Check to see if cell is still on screen, if so update cell
                    if cell == tableView.cellForRow(at: indexPath) {
                        DispatchQueue.main.async {
                            cell.customImageView?.image = cellImage
                            cell.setNeedsLayout()
                        }
                    }
                }
                
            }
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
    
    func didUpdateLocation(town: String, city: String, county: String, postcode: String, country: String, location: CLLocation, distance: Double) {
        configureDatabase(for: location, within: distance)
        rightBarButton.title = town
        print("Delegate called")
    }
}
