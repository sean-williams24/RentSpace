//
//  SearchRadiusViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 12/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit

class SearchRadiusViewController: UIViewController {

    @IBOutlet var locationButton: UIButton!
    @IBOutlet var distanceSlider: UISlider!
    @IBOutlet var distanceLabel: UILabel!
    
    var currentLocation = "SeanTown"
    var searchDistance: Double = 20.00
    var resultsSearchController: UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let addressSearchTable = storyboard!.instantiateViewController(identifier: "AddressSearchTableVC") as! AddressSearchTableViewController
         resultsSearchController = UISearchController(searchResultsController: addressSearchTable)
         resultsSearchController?.searchResultsUpdater = addressSearchTable
//         addressSearchTable.handleAddressSelectionDelegate = self
         
        let titleButton = UIButton()
        titleButton.setTitle("Set Location", for: .normal)
        titleButton.addTarget(self, action: #selector(addressSearch), for: .touchUpInside)
//        titleButton.isUserInteractionEnabled = true
        navigationItem.titleView = titleButton
        
        
        // LOCATION
        
        locationButton.setTitle("\(currentLocation)", for: .normal)
        
        
        
        // DISTANCE
        
        distanceSlider.value = Float(searchDistance)
        distanceLabel.text = "\(Int(searchDistance)) Miles"
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
    
    @IBAction func distanceSliderChanged(_ sender: UISlider) {
        searchDistance = Double(sender.value)
        
        if searchDistance == 1 {
            distanceLabel.text = "\(Int(searchDistance)) Mile"
        } else {
            distanceLabel.text = "\(Int(searchDistance)) Miles"

        }

    }
}
