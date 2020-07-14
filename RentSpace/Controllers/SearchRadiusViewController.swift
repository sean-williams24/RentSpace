//
//  SearchRadiusViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 12/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//
import MapKit
import UIKit

protocol HandleSetSearchLocation {
    func setNewLocation(town: String, city: String, county: String, postcode: String, country: String, location: CLLocation)
}

class SearchRadiusViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet var locationButton: UIButton!
    @IBOutlet var pickerView: UIPickerView!
    @IBOutlet weak var searchButton: UIButton!
    
    
    // MARK: - Properties
    
    var searchDistance: Double = 100.00
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
        
        // Setup search controller
        let addressSearchTable = storyboard!.instantiateViewController(withIdentifier: "ChangeSearchLocationTableVC") as! ChangeSearchLocationTableViewController
        resultsSearchController = UISearchController(searchResultsController: addressSearchTable)
        resultsSearchController?.searchResultsUpdater = addressSearchTable
        addressSearchTable.handleSetSearchLocationDelegate = self
        
        // Navigation bar button
        let titleButton = UIButton()
        let attributedTitle = NSAttributedString(string: "Set Location", attributes: Settings.navBarTitleAttributes)
        titleButton.tintColor = Settings.orangeTint
        titleButton.setAttributedTitle(attributedTitle, for: .normal)
        titleButton.addTarget(self, action: #selector(addressSearch), for: .touchUpInside)
        navigationItem.titleView = titleButton
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view.backgroundColor = .black
        
        searchButton.alpha = 0
        searchButton.layer.cornerRadius = Settings.cornerRadius
        
        // LOCATION
        var currentLocation = UserDefaults.standard.string(forKey: "Location") != nil ? UserDefaults.standard.string(forKey: "Location") : Location.userLocationCity
        if currentLocation == "" {
            currentLocation = Location.userLocationCountry
        }
        
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
        
        for (index, miles) in pickerDistances.enumerated() {
            if Double(miles) == searchDistance {
                pickerView.selectRow(index, inComponent: 0, animated: true)
            }
        }
    }
    
    
    // MARK: - Private Methods
    
    @objc func addressSearch() {
        navigationController?.setNavigationBarHidden(true, animated: true)
        let searchBar = resultsSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Enter Postcode or Address"
        searchBar.tintColor = .white
        searchBar.keyboardAppearance = .dark
        
        let textfieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
        if #available(iOS 13.0, *) {
            textfieldInsideSearchBar?.textColor = .white
        } else {
            textfieldInsideSearchBar?.textColor = .black
        }
        
        self.navigationItem.titleView = self.resultsSearchController?.searchBar
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        resultsSearchController?.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
    }
    
    
    // MARK: - Action Methods
    
    @IBAction func locationButtonTapped(_ sender: Any) {
        addressSearch()
    }
    
    
    @IBAction func searchButtonTapped(_ sender: Any) {
        if locationUpdated {
            delegate?.didUpdateLocation(town: town, city: city, county: county, postcode: postcode, country: country, location: location!, distance: searchDistance)
        }
        
        if distanceUpdated {
            delegate?.didUpdate(distance: searchDistance)
            UserDefaults.standard.set(searchDistance, forKey: "Distance")
        }
        
        self.navigationController?.popViewController(animated: true)
    }
}


// MARK: - Extensions

extension SearchRadiusViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDistances.count
    }
    
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.font = UIFont(name: "HelveticaNeue-Light", size: 16)
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
        searchDistance = Double(pickerDistances[row])!
        distanceUpdated = true
        
        UIView.animate(withDuration: 0.5) {
            self.searchButton.alpha = 1
        }
    }
}


extension SearchRadiusViewController: HandleSetSearchLocation {
    
    func setNewLocation(town: String, city: String, county: String, postcode: String, country: String, location: CLLocation) {

        let subAdminArea = county
        let state = country
        var newLocation = ""
        
        if city == subAdminArea {
            newLocation = "\(town), \(city)"
            if town == "" {
                newLocation = "\(city)"
            }
        } else {
            newLocation = "\(town), \(city), \(subAdminArea)"
            if town == "" {
                newLocation = "\(city), \(subAdminArea)"
            }
        }
        
        if city == "" && town == "" {
            newLocation = subAdminArea
            
            if subAdminArea == "" {
                newLocation = state
            }
        }
        
        locationButton.setTitle(newLocation, for: .normal)
        
        self.town = town
        self.city = city
        self.county = county
        self.postcode = postcode
        self.country = country
        self.location = location
        
        Location.customCLLocation = location
        Location.savedLocationExists = true
        locationUpdated = true
        
        UIView.animate(withDuration: 0.5) {
            self.searchButton.alpha = 1
        }
    }
}
