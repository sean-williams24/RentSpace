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
    func addAddress(address: String)
}

class ContactDetailsViewController: UIViewController, HandleAddressSelection {
    
    func addAddress(address: String) {
        addressTextView.text = address
    }
    
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var phoneNumberTextField: UITextField!
    @IBOutlet var addressSearchButton: UIButton!
    @IBOutlet var addressTextView: UITextView!
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var searchBar: UISearchBar!
    
    let searchRequest = MKLocalSearch.Request()
    var resultsSearchController: UISearchController?
    var selectedAddress = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        saveButton.layer.cornerRadius = 10
        
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
        
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addressTextView.text = selectedAddress
        
        print(selectedAddress)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func addressTextFieldSearch(_ sender: UITextField) {
        
        
    }
    
    
    @IBAction func searchButtonTapped(_ sender: Any) {
//        guard let address = addressTextField.text else { return }
//        CLGeocoder().geocodeAddressString(address) { placemark, error in
//
//            if error != nil {
//                 DispatchQueue.main.async {
//                    // TODO: - Show error alert
////                     self.showErrorAlert(title: "Unknown Location", error: "Problem finding location. Please try again.")
//                 }
//             }
//
//            if let placemarks = placemark {
//                self.addressTextView.text = placemarks.first?.name
//                print(placemarks)
//                print(placemarks.count)
//            }
//        }
        
    }
    
    
    @IBAction func saveButtonTapped(_ sender: Any) {
    }
}


// MARK: - Table View delegates
//
//extension ContactDetailsViewController: UITableViewDelegate, UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        <#code#>
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell", for: indexPath)
//    }
//
//
//
//}



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
