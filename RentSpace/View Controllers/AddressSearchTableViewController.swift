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
    
    var matchingItems: [MKMapItem] = []
    var mapView: MKMapView? = nil
    let formatter = CNPostalAddressFormatter()
    let locationManager = CLLocationManager()
    var userLocation = CLLocation()
    var handleAddressSelectionDelegate: HandleAddressSelection? = nil
    

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.first!
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchBarText = searchController.searchBar.text else { return }
        let request = MKLocalSearch.Request()
        let region = MKCoordinateRegion(center: userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 10000, longitudeDelta: 10000))
        
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
        // #warning Incomplete implementation, return the number of rows
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
                  
            handleAddressSelectionDelegate?.addAddress(name: address.name ?? "", address: formattedAddress,  town: postalAddress.subLocality, city: postalAddress.city, subAdminArea: postalAddress.subAdministrativeArea, state: postalAddress.state, country: postalAddress.country, postCode: postalAddress.postalCode)
            
            UserDefaults.standard.set(postalAddress.subLocality, forKey: "Town")
            UserDefaults.standard.set(postalAddress.city, forKey: "City")
            UserDefaults.standard.set(postalAddress.subAdministrativeArea, forKey: "SubAdminArea")
            UserDefaults.standard.set(postalAddress.state, forKey: "State")
            UserDefaults.standard.set(postalAddress.country, forKey: "Country")
            UserDefaults.standard.set(postalAddress.postalCode, forKey: "PostCode")
        }
        
        dismiss(animated: true)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

