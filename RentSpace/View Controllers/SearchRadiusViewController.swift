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
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var pickerView: UIPickerView!
    
    
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
    var pickerDistances = [String]()
    

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let addressSearchTable = storyboard!.instantiateViewController(identifier: "ChangeSearchLocationTableVC") as! ChangeSearchLocationTableViewController
        resultsSearchController = UISearchController(searchResultsController: addressSearchTable)
        resultsSearchController?.searchResultsUpdater = addressSearchTable
        addressSearchTable.handleSetSearchLocationDelegate = self
         
        let titleButton = UIButton()
        titleButton.tintColor = Settings.orangeTint
        titleButton.setTitle("Set Location", for: .normal)
        titleButton.addTarget(self, action: #selector(addressSearch), for: .touchUpInside)
        navigationItem.titleView = titleButton
        
        // LOCATION
        let currentLocation = UserDefaults.standard.string(forKey: "Location")
        locationButton.setTitle(currentLocation, for: .normal)
        
        locationButton.layer.borderColor = Settings.orangeTint.cgColor
        locationButton.layer.borderWidth = 1
        locationButton.layer.cornerRadius = Settings.cornerRadius
        
        // DISTANCE
        for i in 1...30 {
            pickerDistances.append(String(i))
        }
        for i in stride(from: 40, to: 320, by: 10) {
            pickerDistances.append(String(i))
        }
        
        if UserDefaults.standard.double(forKey: "Distance") != 0.0 {
            searchDistance = UserDefaults.standard.double(forKey: "Distance")
        }
        print("Search Distance: \(searchDistance)")
        
        for (index, miles) in pickerDistances.enumerated() {
            if Double(miles) == searchDistance {
                pickerView.selectRow(index, inComponent: 0, animated: true)
            }
        }
        
        navigationController?.children[1].navigationItem.backBarButtonItem = UIBarButtonItem(title: "-", style: .plain, target: nil, action: nil)

        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if locationUpdated {
            delegate?.didUpdateLocation(town: town, city: city, county: county, postcode: postcode, country: country, location: location!, distance: searchDistance)
        }
        
        if distanceUpdated {
            delegate?.didUpdate(distance: searchDistance)
            UserDefaults.standard.set(searchDistance, forKey: "Distance")
        }
        
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
        navigationController?.children[1].navigationItem.backBarButtonItem = UIBarButtonItem(title: "SEARCH", style: .plain, target: nil, action: nil)

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
    
//    @IBAction func distanceSliderChanged(_ sender: UISlider) {
//        searchDistance = Double(sender.value)
//
//        if searchDistance == 1 {
//            distanceLabel.text = "\(Int(searchDistance)) Mile"
//        } else {
//            distanceLabel.text = "\(Int(searchDistance)) Miles"
//
//        }
//
//        distanceUpdated = true
//
//    }
}


extension SearchRadiusViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // Hide borders of picker view
//        pickerView.subviews.forEach({
//            $0.isHidden = $0.frame.height < 1.0
//        })
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDistances.count
    }
    
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .center
        label.textColor = Settings.orangeTint
        label.layer.borderWidth = .zero
        
        if row == 0 {
            label.text = "1 Mile"
        } else if pickerDistances[row] == "310" {
            label.text = "Nationwide"
        } else {
            label.text = "\(pickerDistances[row]) Miles"
        }
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        view.endEditing(true)
        searchDistance = Double(pickerDistances[row])!
        distanceUpdated = true
        
        navigationController?.children[1].navigationItem.backBarButtonItem = UIBarButtonItem(title: "SEARCH", style: .plain, target: nil, action: nil)
    }
    
    
    
}
