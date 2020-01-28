//
//  ContactDetailsViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 29/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit
import MapKit
import Contacts

protocol HandleAddressSelection {
    func addAddress(name: String, address: String, town: String, city: String, subAdminArea: String, state: String, country: String, postCode: String)
}

class ContactDetailsViewController: UIViewController, HandleAddressSelection {
    
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var phoneNumberTextField: UITextField!
    @IBOutlet var streetLabel: UITextField!
    @IBOutlet var townLabel: UITextField!
    @IBOutlet var cityLabel: UITextField!
    @IBOutlet var countyLabel: UITextField!
    @IBOutlet var stateLabel: UITextField!
    @IBOutlet var countryLabel: UITextField!
    @IBOutlet var postcodeLabel: UITextField!
    @IBOutlet var viewOnMapSwitch: UISwitch!
    
    
    let searchRequest = MKLocalSearch.Request()
    var resultsSearchController: UISearchController?
    var selectedAddress = ""
    var inUpdateMode = false
    var advert: [String : Any] = [:]
    
    //    var viewOnMap = true
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let addressSearchTable = storyboard!.instantiateViewController(identifier: "AddressSearchTableVC") as! AddressSearchTableViewController
        resultsSearchController = UISearchController(searchResultsController: addressSearchTable)
        resultsSearchController?.searchResultsUpdater = addressSearchTable
        addressSearchTable.handleAddressSelectionDelegate = self
        
        let searchBar = resultsSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Enter Postcode or Address"
        searchBar.keyboardAppearance = .dark    
        navigationItem.titleView = resultsSearchController?.searchBar
        
        resultsSearchController?.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        
        configureTextFieldPlaceholders(for: emailTextField, withText: "Email")
        configureTextFieldPlaceholders(for: phoneNumberTextField, withText: "Phone")
        configureTextFieldPlaceholders(for: streetLabel, withText: "Street")
        configureTextFieldPlaceholders(for: townLabel, withText: "Town")
        configureTextFieldPlaceholders(for: cityLabel, withText: "City")
        configureTextFieldPlaceholders(for: countyLabel, withText: "County")
        configureTextFieldPlaceholders(for: countryLabel, withText: "Country")
        configureTextFieldPlaceholders(for: postcodeLabel, withText: "Postcode")
        configureTextFieldPlaceholders(for: stateLabel, withText: "State")
        
        if Constants.userLocationCountry == "United States" {
            configureTextFieldPlaceholders(for: postcodeLabel, withText: "Zip Code")
            
        }
        
        if inUpdateMode {
            emailTextField.text = UserDefaults.standard.string(forKey: "UpdateEmail")
            phoneNumberTextField.text = UserDefaults.standard.string(forKey: "UpdatePhone")
            townLabel.text = UserDefaults.standard.string(forKey: "UpdateTown")
            cityLabel.text = UserDefaults.standard.string(forKey: "UpdateCity")
            countyLabel.text = UserDefaults.standard.string(forKey: "UpdateSubAdminArea")
            stateLabel.text = UserDefaults.standard.string(forKey: "UpdateState")
            countryLabel.text = UserDefaults.standard.string(forKey: "UpdateCountry")
            postcodeLabel.text = UserDefaults.standard.string(forKey: "UpdatePostCode")
            viewOnMapSwitch.setOn(UserDefaults.standard.bool(forKey: "UpdateViewOnMap"), animated: true)
            
        } else {
            // If email textfield is empty, set it to current users email address
            emailTextField.text = UserDefaults.standard.string(forKey: "Email")
            if emailTextField.text == "" {
                if let email = Settings.currentUser?.email {
                    emailTextField.text = email
                }
            }
            
            phoneNumberTextField.text = UserDefaults.standard.string(forKey: "Phone")
            townLabel.text = UserDefaults.standard.string(forKey: "Town")
            cityLabel.text = UserDefaults.standard.string(forKey: "City")
            countyLabel.text = UserDefaults.standard.string(forKey: "SubAdminArea")
            stateLabel.text = UserDefaults.standard.string(forKey: "State")
            countryLabel.text = UserDefaults.standard.string(forKey: "Country")
            postcodeLabel.text = UserDefaults.standard.string(forKey: "PostCode")
            viewOnMapSwitch.isOn = UserDefaults.standard.bool(forKey: "ViewOnMap")
            
            dismissKeyboardOnViewTap()
        }
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if inUpdateMode {
            UserDefaults.standard.set(emailTextField.text, forKey: "UpdateEmail")
            UserDefaults.standard.set(phoneNumberTextField.text, forKey: "UpdatePhone")
            UserDefaults.standard.set(townLabel.text, forKey: "UpdateTown")
            UserDefaults.standard.set(cityLabel.text, forKey: "UpdateCity")
            UserDefaults.standard.set(countyLabel.text, forKey: "UpdateSubAdminArea")
            UserDefaults.standard.set(stateLabel.text, forKey: "UpdateState")
            UserDefaults.standard.set(countryLabel.text, forKey: "UpdateCountry")
            UserDefaults.standard.set(postcodeLabel.text, forKey: "UpdatePostCode")
            UserDefaults.standard.set(viewOnMapSwitch.isOn, forKey: "UpdateViewOnMap")
        } else {
            UserDefaults.standard.set(emailTextField.text, forKey: "Email")
            UserDefaults.standard.set(phoneNumberTextField.text, forKey: "Phone")
            UserDefaults.standard.set(townLabel.text, forKey: "Town")
            UserDefaults.standard.set(cityLabel.text, forKey: "City")
            UserDefaults.standard.set(countyLabel.text, forKey: "SubAdminArea")
            UserDefaults.standard.set(stateLabel.text, forKey: "State")
            UserDefaults.standard.set(countryLabel.text, forKey: "Country")
            UserDefaults.standard.set(postcodeLabel.text, forKey: "PostCode")
            UserDefaults.standard.set(viewOnMapSwitch.isOn, forKey: "ViewOnMap")
        }
        
    }
    
    
    
    
    // MARK: - Private Methods
    
    
    
    
    func addAddress(name: String, address: String, town: String, city: String, subAdminArea: String, state: String, country: String, postCode: String) {
        
        //        streetLabel.text = street
        
        if town == "" {
            townLabel.isHidden = true
        } else {
            townLabel.isHidden = false
            townLabel.text = town
        }
        cityLabel.text = city
        countyLabel.text = subAdminArea
        stateLabel.text = state
        countryLabel.text = country
        postcodeLabel.text = postCode

        
    }
    
    //MARK: - Action Methods
    
    @IBAction func mapSelectionSwitchTapped(_ sender: UISwitch) {
        //
        //        viewOnMap = sender.isOn
        //        print(viewOnMap)
    }
    
    
    
}

// MARK: - Search bar delegates

extension ContactDetailsViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        for textFieldToReturn in self.view.subviews where textFieldToReturn is UITextField {
            textField.resignFirstResponder()
        }
        return true
    }
    
    // - Move screen up
    //    @objc func keyboardWillShow(_ notifictation: Notification) {
    //        if postcodeLabel.isEditing || countryLabel.isEditing || stateLabel.isEditing {
    //            view.frame.origin.y = CGFloat(integerLiteral: -100)
    //        }
    //    }
    
}
