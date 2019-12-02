//
//  ContactDetailsViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 29/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit
import MapKit

protocol HandleAddressSelection {
    func addAddress(name: String, address: String)
}

class ContactDetailsViewController: UIViewController, HandleAddressSelection {
    
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var phoneNumberTextField: UITextField!
    @IBOutlet var addressTextView: UITextView!
    
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
        searchBar.placeholder = "Search Address"
        searchBar.keyboardAppearance = .dark    
        navigationItem.titleView = resultsSearchController?.searchBar
        
        resultsSearchController?.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        
        addressTextView.layer.cornerRadius = 5
        
        emailTextField.attributedPlaceholder = NSAttributedString(string: "Email", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        phoneNumberTextField.attributedPlaceholder = NSAttributedString(string: "Phone", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        emailTextField.text = UserDefaults.standard.string(forKey: "Email")
        phoneNumberTextField.text = UserDefaults.standard.string(forKey: "Phone")
        addressTextView.text = UserDefaults.standard.string(forKey: "Address")
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UserDefaults.standard.set(emailTextField.text, forKey: "Email")
        UserDefaults.standard.set(phoneNumberTextField.text, forKey: "Phone")
        UserDefaults.standard.set(addressTextView.text, forKey: "Address")
    }
    



    // MARK: - Private Methods

    func addAddress(name: String, address: String) {
        if address.contains(name) {
            addressTextView.text = address
        } else {
            addressTextView.text = "\(name) \n\(address)"
        }
    }

}

// MARK: - Search bar delegates

extension ContactDetailsViewController: UISearchBarDelegate {
    
//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        searchRequest.naturalLanguageQuery = searchBar.text
//        let search = MKLocalSearch(request: searchRequest)
//        
//        search.start { response, error in
//            guard let response = response  else {
//                print("Error: \(error?.localizedDescription ?? "Unknown error").")
//                return
//            }
//            for item in response.mapItems {
//                print(item.placemark.name)
//                self.addressTextView.text = item.placemark.name
//            }
//            
//        }
//    }
    

}
