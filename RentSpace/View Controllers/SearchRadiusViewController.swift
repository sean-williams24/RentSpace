//
//  SearchRadiusViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 12/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//
import MapKit
import UIKit

protocol handleSetSearchLocation {
    func setNewLocation(town: String, city: String, county: String, postcode: String, country: String, location: CLLocation)
}

class SearchRadiusViewController: UIViewController, handleSetSearchLocation {

    @IBOutlet var locationButton: UIButton!
    @IBOutlet var distanceSlider: UISlider!
    @IBOutlet var distanceLabel: UILabel!
    
//    var currentLocation = "SeanTown"
    var searchDistance: Double = 20.00
    var resultsSearchController: UISearchController?
    var delegate: UpdateSearchLocationDelegate?
    var town: String!
    var city: String!
    var county: String!
    var postcode: String!
    var country: String!
    var location: CLLocation?
    var locationUpdated = false
    var distanceUpdated = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let addressSearchTable = storyboard!.instantiateViewController(identifier: "ChangeSearchLocationTableVC") as! ChangeSearchLocationTableViewController
        resultsSearchController = UISearchController(searchResultsController: addressSearchTable)
        resultsSearchController?.searchResultsUpdater = addressSearchTable
        addressSearchTable.handleSetSearchLocationDelegate = self
         
        let titleButton = UIButton()
        titleButton.setTitle("Set Location", for: .normal)
        titleButton.addTarget(self, action: #selector(addressSearch), for: .touchUpInside)
        navigationItem.titleView = titleButton
        
        
        // LOCATION
        let currentLocation = UserDefaults.standard.string(forKey: "Location")
        locationButton.setTitle(currentLocation, for: .normal)
        
        
        
        // DISTANCE
        
        searchDistance = UserDefaults.standard.double(forKey: "Distance")
        
        distanceSlider.value = Float(searchDistance)
        distanceLabel.text = "\(Int(searchDistance)) Miles"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if locationUpdated {
            delegate?.didUpdateLocation(town: town, city: city, county: county, postcode: postcode, country: country, location: location!, distance: searchDistance)
            UserDefaults.standard.set(postcode, forKey: "LocationPostcode")
        }
        
        if distanceUpdated {
            delegate?.didUpdate(distance: searchDistance)
        }
        
        UserDefaults.standard.set(searchDistance, forKey: "Distance")
    }
    
    // MARK: - Private Methods
    
    func setNewLocation(town: String, city: String, county: String, postcode: String, country: String, location: CLLocation) {
        if town == "" {
            locationButton.setTitle("\(city), \(postcode)", for: .normal)
            if city == "" {
                locationButton.setTitle(postcode, for: .normal)
            }
            if postcode == "" {
                 locationButton.setTitle("\(city), \(country)", for: .normal)
             }
        } else {
            locationButton.setTitle("\(town), \(postcode)", for: .normal)
            if postcode == "" {
                locationButton.setTitle("\(town), \(county)", for: .normal)
            }
        }
        
        self.town = town
        self.city = city
        self.county = county
        self.postcode = postcode
        self.country = country
        self.location = location
        
        Constants.customCLLocation = location
        
        locationUpdated = true
    }
    
    

    @objc func addressSearch() {
        navigationController?.setNavigationBarHidden(true, animated: true)
        let searchBar = resultsSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Enter Postcode or Address"
        searchBar.keyboardAppearance = .dark
        self.navigationItem.titleView = self.resultsSearchController?.searchBar
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        resultsSearchController?.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
    }

    // MARK: - Action Methods

    @IBAction func locationButtonTapped(_ sender: Any) {
        addressSearch()
    }
    
    @IBAction func distanceSliderChanged(_ sender: UISlider) {
        searchDistance = Double(sender.value)
        
        if searchDistance == 1 {
            distanceLabel.text = "\(Int(searchDistance)) Mile"
        } else {
            distanceLabel.text = "\(Int(searchDistance)) Miles"

        }
        
        distanceUpdated = true
    }
}
