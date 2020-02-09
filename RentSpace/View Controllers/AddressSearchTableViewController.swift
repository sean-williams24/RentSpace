//
//  AddressSearchTableViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 29/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit
import MapKit
import Contacts

class AddressSearchTableViewController: UITableViewController, UISearchResultsUpdating, CLLocationManagerDelegate {
    
    // MARK: - Properties
    
    var matchingItems: [MKMapItem] = []
    var mapView: MKMapView? = nil
    let formatter = CNPostalAddressFormatter()
    var handleAddressSelectionDelegate: HandleAddressSelection? = nil
    
    
    // MARK: - Life Cycle
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchBarText = searchController.searchBar.text else { return }
        
        let request = MKLocalSearch.Request()
        let region = MKCoordinateRegion(center: Location.userCLLocation.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        request.naturalLanguageQuery = searchBarText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {
                print("Error: \(error?.localizedDescription ?? "Unkown Error")")
                return
            }
            self.matchingItems = response.mapItems
            self.tableView.reloadData()
        }
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell", for: indexPath)
        let address = matchingItems[indexPath.row].placemark
        cell.textLabel?.text = address.name
        
        if let postalAddress = address.postalAddress {
            cell.detailTextLabel?.text = formatter.string(from: postalAddress).replacingOccurrences(of: "\n", with: ", ")
        }
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let address = matchingItems[indexPath.row].placemark
        if let postalAddress = address.postalAddress {
            let formattedAddress = formatter.string(from: postalAddress)
            
            handleAddressSelectionDelegate?.addAddress(name: address.name ?? "", address: formattedAddress, town: postalAddress.subLocality, city: postalAddress.city, subAdminArea: postalAddress.subAdministrativeArea, state: postalAddress.state, country: postalAddress.country, postCode: postalAddress.postalCode)
            
            UserDefaults.standard.set(postalAddress.subLocality, forKey: "Town")
            UserDefaults.standard.set(postalAddress.city, forKey: "City")
            UserDefaults.standard.set(postalAddress.subAdministrativeArea, forKey: "SubAdminArea")
            UserDefaults.standard.set(postalAddress.state, forKey: "State")
            UserDefaults.standard.set(postalAddress.country, forKey: "Country")
            UserDefaults.standard.set(postalAddress.postalCode, forKey: "PostCode")
        }
        
        dismiss(animated: true)
    }
}

