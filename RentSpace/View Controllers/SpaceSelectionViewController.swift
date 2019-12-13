//
//  SpaceSelectionViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 06/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit
import MapKit

class SpaceSelectionViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet var artButton: UIButton!
    @IBOutlet var photographyButton: UIButton!
    @IBOutlet var musicButton: UIButton!
    @IBOutlet var deskButton: UIButton!
    
    var locationManager: CLLocationManager!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure(artButton, text: "Art")
        configure(photographyButton, text: "Photography")
        configure(musicButton, text: "Music")
        configure(deskButton, text: "Desk Space")
        
        let savedLocation = UserDefaults.standard.string(forKey: "Location")
        if let savedLocation = savedLocation {
            CLGeocoder().geocodeAddressString(savedLocation) { (placemark, error) in
                if error != nil {
                    print("Error geocoding users location: \(error?.localizedDescription ?? "")")
                }
                if let location = placemark?[0].location {
                    Constants.customCLLocation = location
                }
            }
        }

        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.first else { return }
        
        CLGeocoder().reverseGeocodeLocation(userLocation) { (placemark, error) in
            if error != nil {
                print("Error geocoding users location: \(error?.localizedDescription ?? "")")
            }
            
            if let address = placemark?[0].postalAddress {
                Constants.userLocationTown = address.subLocality
                Constants.userLocationCity = address.city
                Constants.userLocationCountry = address.country
                Constants.userLocationAddress = address
                Constants.userCLLocation = userLocation
            }
        }
        locationManager.stopUpdatingLocation()
    }
    
    
    // MARK: - Private Methods
    
    func configure(_ button: UIButton, text: String) {
        button.imageView?.contentMode = .scaleAspectFill
        button.imageView?.layer.cornerRadius = 8
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 0.4
        button.layer.borderColor = UIColor.white.cgColor
        button.backgroundColor = .clear
        button.layer.shadowColor = UIColor.darkGray.cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 4
        button.layer.shadowOffset = CGSize(width: 1, height: 2)
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "Snell Roundhand", size: 30)
        label.textColor = .white
        label.text = text
        label.textAlignment = .center
        button.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 28),
        ])
    }

    
    // MARK: - Navigation


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! RentSpaceViewController
        let button = sender as! UIButton
        vc.location = Constants.userLocationCountry
        
        switch button.tag {
        case 0:
            vc.chosenCategory = "Art Studio"
        case 1:
            vc.chosenCategory = "Photography Studio"
        case 2:
            vc.chosenCategory = "Music Studio"
        case 3:
            vc.chosenCategory = "Desk Space"
        default:
            vc.chosenCategory = "Art Studio"
        }
        
    }
    
    
    
    @IBAction func buttonTapped(_ sender: UIButton) {
//        let vc = storyboard?.instantiateViewController(identifier: "RentSpaceVC") as! RentSpaceViewController
        
    }
    
}
