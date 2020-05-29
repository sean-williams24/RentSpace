//
//  ChangeSearchLocationTableViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 13/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import Contacts
import MapKit
import UIKit

class ChangeSearchLocationTableViewController: UITableViewController, UISearchResultsUpdating {
    
    // MARK: - Properties
    
    var matchingItems: [MKMapItem] = []
    var handleSetSearchLocationDelegate: HandleSetSearchLocation?
    
    
    // MARK: - Search Results
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchBarText = searchController.searchBar.text else { return }
        let request = MKLocalSearch.Request()
        let region = MKCoordinateRegion(center: Location.userCLLocation.coordinate, latitudinalMeters: 13000, longitudinalMeters: 13000)
        request.naturalLanguageQuery = searchBarText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {
                print("Error: \(error?.localizedDescription ?? "Unkown Error")")
                return
            }
            
            self.matchingItems.removeAll()
            for item in response.mapItems {
                if item.placemark.country == Location.userLocationCountry {
                    self.matchingItems.append(item)
                }
            }

            self.tableView.reloadData()
        }
    }
    
    // MARK: - Table view Delegates
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell", for: indexPath)
        let address = matchingItems[indexPath.row].placemark
        cell.textLabel?.backgroundColor = .clear
        cell.detailTextLabel?.backgroundColor = .clear
        
        if let postalAddress = address.postalAddress {
            cell.textLabel?.text = postalAddress.subLocality
            cell.detailTextLabel?.text = "\(postalAddress.city), \(postalAddress.postalCode)"
            
            if postalAddress.subLocality == "" {
                cell.textLabel?.text = postalAddress.city
                cell.detailTextLabel?.text = postalAddress.subAdministrativeArea
                
                if postalAddress.city == postalAddress.subAdministrativeArea {
                    cell.textLabel?.text = postalAddress.city
                    cell.detailTextLabel?.text = postalAddress.state
                }
                
                if postalAddress.city == "" {
                    cell.textLabel?.text = postalAddress.subAdministrativeArea
                    cell.detailTextLabel?.text = postalAddress.state
                }
            }
        }
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let address = matchingItems[indexPath.row].placemark
        let location = address.location ?? Location.userCLLocation
        
        if let postalAddress = address.postalAddress {
            handleSetSearchLocationDelegate?.setNewLocation(town: postalAddress.subLocality, city: postalAddress.city, county: postalAddress.subAdministrativeArea, postcode: postalAddress.postalCode, country: postalAddress.state, location: location)
        }
        
        dismiss(animated: true)
    }
}
