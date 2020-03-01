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
    
    // MARK: - Outlets
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var activityView: NVActivityIndicatorView!
    @IBOutlet var loadingLabel: UILabel!
    @IBOutlet var arrow: UIImageView!
    @IBOutlet weak var firstLoadInfoView: UIView!
    @IBOutlet weak var firstLoadViewCentre: NSLayoutConstraint!
    @IBOutlet weak var firstLoadLabel: UILabel!
    @IBOutlet weak var blurredView: UIVisualEffectView!
    
    // MARK: - Properties
    
    var ref: DatabaseReference!
    var storageRef: StorageReference!
    var spaces: [Space] = []
    var chosenCategory = ""
    var location = ""
    var searchAreaButtonTitle = ""
    var rightBarButton = UIBarButtonItem()
    
    
    // MARK: - Life Cycle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title of location button to saved user location. If none then users current location.
        
        if let UDTitle = UserDefaults.standard.string(forKey: "Location") {
            searchAreaButtonTitle = UDTitle.uppercased()
        } else {
            if let town = Location.userLocationAddress?.subLocality {
                searchAreaButtonTitle = town.uppercased()
                if town == "" {
                    searchAreaButtonTitle = Location.userLocationAddress?.city ?? "Search Area"
                }
            } else if let city = Location.userLocationAddress?.city {
                searchAreaButtonTitle = city.uppercased()
            } else if let postcode = Location.userLocationAddress?.postalCode {
                searchAreaButtonTitle = postcode.uppercased()
            }
        }
        
        rightBarButton = UIBarButtonItem(title: searchAreaButtonTitle, style: .done, target: self, action: #selector(setSearchRadius))
        rightBarButton.setTitleTextAttributes(Settings.barButtonAttributes, for: .normal)
        navigationItem.rightBarButtonItem = rightBarButton

        
        storageRef = FirebaseClient.storageRef
        ref = FirebaseClient.databaseRef
        
        if UserDefaults.standard.double(forKey: "Distance") != 0.0 {
            Location.searchDistance = UserDefaults.standard.double(forKey: "Distance")
        } 
        
        if Location.savedLocationExists == true {
            getAdverts(for: Location.customCLLocation, within: Location.searchDistance)
        } else {
            getAdverts(for: Location.userCLLocation, within: Location.searchDistance)
        }
        
        self.tableView.rowHeight = 150
        
        UIView.animate(withDuration: 0.3) {
            self.blurredView.isHidden = false
        }
        let area = searchAreaButtonTitle.lowercased().capitalized
        area.capitalized
        firstLoadLabel.text = "Showing results for \(chosenCategory)'s in \(searchAreaButtonTitle.lowercased().capitalized) within a 100 mile radius. \n\nChange location and search radius by tapping the \(searchAreaButtonTitle.lowercased().capitalized) button above."
        firstLoadInfoView.backgroundColor = Settings.flipsideBlackColour
        firstLoadInfoView.layer.cornerRadius = 10
        firstLoadInfoView.layer.borderWidth = 1
//        firstLoadInfoView.layer.borderColor = UIColor.white.cgColor
        firstLoadViewCentre.constant = 0
        UIView.animate(withDuration: 0.9, delay: 0.3, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }) { _ in
            //
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if Auth.auth().currentUser != nil {
            self.tabBarController?.tabBar.isHidden = false
        } else {
            self.tabBarController?.tabBar.isHidden = true
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.arrow.alpha = 0

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.spaces.isEmpty {
                self.arrow.isHidden = false
                UIView.animate(withDuration: 1) {
                    self.loadingLabel.alpha = 0
                    self.loadingLabel.text = "No spaces were found, try expanding your search radius and check your connection"
                    UIView.animate(withDuration: 3) {
                        self.loadingLabel.alpha = 1
                        self.arrow.alpha = 1
                    }
                }
                self.activityView.stopAnimating()
                self.arrow.blink(duration: 0.7, delay: 0, alpha: 0.05)
            }
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UserDefaults.standard.set(rightBarButton.title, forKey: "Location")
    }
    

    
    // MARK: - Private Methods
    
    fileprivate func startCellLoadingActivityView() {
        let indexPath = IndexPath(row: 0, section: self.tableView.numberOfSections - 1)
        guard let cell = self.tableView.cellForRow(at: indexPath) as? AdvertTableViewCell else { return }
        cell.activityView.startAnimating()
    }
    
    fileprivate func getDistancesOfAdverts(for snapshot: DataSnapshot, from userLocation: CLLocation, within setMiles: Double, filtering: Bool) {
        let spaceCount = snapshot.children.allObjects.count
        var index = 0
        var newSpaces: [Space] = []
        
        for child in snapshot.children {
            if let spaceSnapshot = child as? DataSnapshot,
                var space = Space(snapshot: spaceSnapshot) {
                var address = ""
                address = space.postcode + " " + space.city + " " + space.subAdminArea + " " + space.state

                // Get distance of advert location from users chosen location and add to table if within search radius
                CLGeocoder().geocodeAddressString(address) { (placemark, error) in
                    if let placemark = placemark?.first {
                        let advertLocation = placemark.location
                        if let distance = advertLocation?.distance(from: userLocation) {
                            let distanceInMiles = distance / 1609.344
                            
                            if filtering {
                                if distanceInMiles < setMiles {
                                    space.distance = distanceInMiles
                                    newSpaces.append(space)
                                    self.showLoadingUI(false, for: self.activityView, label: self.loadingLabel)
                                }
                            } else {
                                space.distance = distanceInMiles
                                newSpaces.append(space)
                                self.showLoadingUI(false, for: self.activityView, label: self.loadingLabel)
                            }
                            
                            index += 1
                            if index == spaceCount {
                                self.spaces = newSpaces.sorted {
                                    $0.distance < $1.distance
                                }
                                self.tableView.reloadData()
                                self.arrow.isHidden = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getAdverts(for userLocation: CLLocation, within setMiles: Double) {
        self.showLoadingUI(true, for: self.activityView, label: self.loadingLabel)
        
        spaces.removeAll()
        tableView.reloadData()
        
        if setMiles == 310.0 {
            // Nationwide results, i.e. all adverts
            ref.child("adverts/\(location)/\(chosenCategory)").observe(.value, with: { (snapshot) in
                self.getDistancesOfAdverts(for: snapshot, from: userLocation, within: setMiles, filtering: false)
            })
        } else {
            ref.child("adverts/\(location)/\(chosenCategory)").observe(.value, with: { (snapshot) in
                self.getDistancesOfAdverts(for: snapshot, from: userLocation, within: setMiles, filtering: true)
            })
        }
    }
    
    
    @objc func setSearchRadius() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "SearchRadiusVC") as! SearchRadiusViewController
        vc.delegate = self
        show(vc, sender: self)
    }
    
    
    // MARK: - Action Methods

    @IBAction func gotItButtonTapped(_ sender: Any) {
        firstLoadViewCentre.constant = -1000
        UIView.animate(withDuration: 0.9, delay: 0.3, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
             self.view.layoutIfNeeded()
         }) { _ in
            self.blurredView.isHidden = true
         }

    }
}


// MARK: - TableView Delegates & Datasource


extension RentSpaceViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return spaces.count
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
        let space = spaces[indexPath.section]
        
        cell.layer.borderWidth = 1
        cell.customImageView.image = nil
        cell.activityView.startAnimating()
        cell.customImageView.layer.borderColor = Settings.flipsideBlackColour.cgColor
        cell.customImageView.layer.borderWidth = 1
        cell.customImageView.layer.cornerRadius = 10
        cell.customImageView.alpha = 1
        cell.titleLabel.text = space.title.uppercased()
        cell.descriptionLabel.text = space.description
        cell.categoryLabel.text = space.category
        cell.locationLabel.text = formatAddress(for: space)
        cell.priceLabel.text = "£\(space.price) \(priceRateFormatter(rate: space.priceRate))"
        cell.distanceLabel.text = "\(Int(space.distance)) miles"
        if space.distance < 1 {
            cell.distanceLabel.text = "Less than a mile"
        }
        
        if let imageURLsDict = space.photos {
            if let imageURL = imageURLsDict["image 1"] {
                
                DispatchQueue.global(qos: .background).async {
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
                                cell.customImageView.transform = CGAffineTransform(scaleX: 1, y: 1)
                                cell.customImageView.contentMode = .scaleAspectFill
                                cell.customImageView?.image = cellImage
                                cell.setNeedsLayout()
                            }
                        }
                    }
                }
            }
        } else {
            cell.activityView.stopAnimating()
            if space.category == "Art Studio" {
                
                // Scale Art studio image down to match SFSymbol icons and add another view to get matching image border
                let view = UIView()
                view.frame = CGRect(x: 10, y: 10, width: 130, height: 130)
                view.layer.borderColor = UIColor.darkGray.cgColor
                view.layer.borderWidth = 1
                cell.addSubview(view)
                
                cell.customImageView.image = iconThumbnail(for: space.category)
                cell.customImageView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                cell.customImageView.contentMode = .scaleAspectFit
                cell.customImageView.layer.borderWidth = 0
                
            } else {
                cell.activityView.stopAnimating()
                cell.customImageView.transform = CGAffineTransform(scaleX: 1, y: 1)
                cell.customImageView.image = iconThumbnail(for: space.category)
                cell.customImageView.contentMode = .scaleAspectFit
                cell.customImageView.layer.borderWidth = 1
            }
            cell.customImageView.tintColor = UIColor.darkGray
            cell.customImageView.layer.borderColor = UIColor.darkGray.cgColor
            cell.customImageView.alpha = 0.7
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "AdvertDetailsVC") as! AdvertDetailsViewController
        vc.space = spaces[indexPath.section]
        show(vc, sender: self)
    }
    
}

extension RentSpaceViewController: UpdateSearchLocationDelegate {
    
    func didUpdate(distance: Double) {
        if Location.savedLocationExists == true {
            getAdverts(for: Location.customCLLocation, within: distance)
        } else {
            getAdverts(for: Location.userCLLocation, within: distance)
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
