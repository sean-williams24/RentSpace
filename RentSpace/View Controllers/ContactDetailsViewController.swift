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
    @IBOutlet var addressSearchButton: UIButton!
    @IBOutlet var addressTextView: UITextView!
    @IBOutlet var searchBar: UISearchBar!
    
    let searchRequest = MKLocalSearch.Request()
    var resultsSearchController: UISearchController?
    var selectedAddress = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let addressSearchTable = storyboard!.instantiateViewController(identifier: "AddressSearchTableVC") as! AddressSearchTableViewController
        resultsSearchController = UISearchController(searchResultsController: addressSearchTable)
        resultsSearchController?.searchResultsUpdater = addressSearchTable
        addressSearchTable.handleAddressSelectionDelegate = self
        
        let searchBar1 = resultsSearchController!.searchBar
        searchBar1.sizeToFit()
        searchBar1.placeholder = "Search Address"
        navigationItem.titleView = resultsSearchController?.searchBar
        
        resultsSearchController?.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        
        addressTextView.layer.cornerRadius = 5
        
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addressTextView.text = selectedAddress
        
        print(selectedAddress)
    }
    
    // MARK: - Action Methods

    
    @IBAction func saveButtonTapped(_ sender: Any) {
    }



    // MARK: - Private Methods

    func addAddress(name: String, address: String) {
        addressTextView.text = "\(name) \n\(address)"
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
