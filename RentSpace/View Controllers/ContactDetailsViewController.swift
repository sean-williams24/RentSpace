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
    func addAddress(name: String, address: String, street: String, town: String, city: String, subAdminArea: String, state: String, country: String, postCode: String)
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
    
    
    let searchRequest = MKLocalSearch.Request()
    var resultsSearchController: UISearchController?
    var selectedAddress = ""
    
    
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
                
//        configureTextFieldPlaceholders(for: emailTextField, withText: "Email")
        configureTextFieldPlaceholders(for: phoneNumberTextField, withText: "Phone")
        configureTextFieldPlaceholders(for: streetLabel, withText: "Street")
        configureTextFieldPlaceholders(for: townLabel, withText: "Town")
        configureTextFieldPlaceholders(for: cityLabel, withText: "City")
        configureTextFieldPlaceholders(for: countyLabel, withText: "County")
        configureTextFieldPlaceholders(for: countryLabel, withText: "Country")
        configureTextFieldPlaceholders(for: postcodeLabel, withText: "Postcode")
        configureTextFieldPlaceholders(for: stateLabel, withText: "State")
        
        if Constants.userLocation == "United States" {
            configureTextFieldPlaceholders(for: postcodeLabel, withText: "Zip Code")

        }

        emailTextField.text = UserDefaults.standard.string(forKey: "Email")
        phoneNumberTextField.text = UserDefaults.standard.string(forKey: "Phone")
        streetLabel.text = UserDefaults.standard.string(forKey: "Street")
        townLabel.text = UserDefaults.standard.string(forKey: "Town")
        cityLabel.text = UserDefaults.standard.string(forKey: "City")
        countyLabel.text = UserDefaults.standard.string(forKey: "SubAdminArea")
        stateLabel.text = UserDefaults.standard.string(forKey: "State")
        countryLabel.text = UserDefaults.standard.string(forKey: "Country")
        postcodeLabel.text = UserDefaults.standard.string(forKey: "PostCode")
        
        // Keyboard dismissal
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        view.addGestureRecognizer(tap)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UserDefaults.standard.set(emailTextField.text, forKey: "Email")
        UserDefaults.standard.set(phoneNumberTextField.text, forKey: "Phone")
        UserDefaults.standard.set(streetLabel.text, forKey: "Street")
        UserDefaults.standard.set(townLabel.text, forKey: "Town")
        UserDefaults.standard.set(cityLabel.text, forKey: "City")
        UserDefaults.standard.set(countyLabel.text, forKey: "SubAdminArea")
        UserDefaults.standard.set(stateLabel.text, forKey: "State")
        UserDefaults.standard.set(countryLabel.text, forKey: "Country")
        UserDefaults.standard.set(postcodeLabel.text, forKey: "PostCode")
    }
    



    // MARK: - Private Methods

    fileprivate func configureTextFieldPlaceholders(for textField: UITextField, withText: String) {
        textField.attributedPlaceholder = NSAttributedString(string: withText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        phoneNumberTextField.attributedPlaceholder = NSAttributedString(string: "Phone", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        emailTextField.attributedPlaceholder = NSAttributedString(string: "Email", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
    }
    
    
    func addAddress(name: String, address: String, street: String, town: String, city: String, subAdminArea: String, state: String, country: String, postCode: String) {
        
        streetLabel.text = street
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
