//
//  SpaceSelectionViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 06/12/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UserNotifications
import Firebase
import UIKit
import MapKit

class SpaceSelectionViewController: UIViewController, CLLocationManagerDelegate {
    
    // MARK: - Outlets

    @IBOutlet var artButton: UIButton!
    @IBOutlet var photographyButton: UIButton!
    @IBOutlet var musicButton: UIButton!
    @IBOutlet var deskButton: UIButton!
    @IBOutlet var signInButton: UIBarButtonItem!
    
    
    // MARK: - Properties

    var locationManager: CLLocationManager!
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure(artButton, text: "Art")
        configure(photographyButton, text: "Photography")
        configure(musicButton, text: "Music")
        configure(deskButton, text: "Desk Space")
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
            if error != nil {
                DispatchQueue.main.async {
                    self.showAlert(title: "Notifications", message: "Without notifications on you may miss messages from customers. Notifications can be turned on in the Settings App.")
                }
            }
        }
                
        
        // If a custom user location exists - store to Location class
        
        let savedLocation = UserDefaults.standard.string(forKey: "Location")
        let savedLocationPostcode = UserDefaults.standard.string(forKey: "LocationPostcode") ?? ""
        
        if let savedLocation = savedLocation {
            Location.savedLocationExists = true
            CLGeocoder().geocodeAddressString(savedLocation + " " + savedLocationPostcode) { (placemark, error) in
                if error != nil {
                    print("Error geocoding users location: \(error?.localizedDescription ?? "")")
                }
                if let location = placemark?[0].location {
                    Location.customCLLocation = location
                }
            }
        }
        
        let registerVC = storyboard?.instantiateViewController(identifier: "RegisterVC") as! RegisterViewController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        registerVC.delegate = self
        appDelegate.delegate = self
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
        
        if let UID = Auth.auth().currentUser?.uid {
            let ref = FirebaseClient.ref
            
            // Load and listen for changes to Favourites
            ref.child("users/\(UID)/favourites").observe(.value) { (snapshot) in
                var newItems: [FavouriteSpace] = []
                for child in snapshot.children {
                    if let favSnap = child as? DataSnapshot {
                        if let favourite = FavouriteSpace(snapshot: favSnap) {
                            newItems.append(favourite)
                        }
                    }
                }
                Favourites.spaces = newItems
            }
            
            
            // Check for unread messages
            ref.child("users/\(UID)/chats").observe(.value, with: { (dataSnapshot) in
                var unread = 0
                var read = 0
                let messageTab = self.tabBarController?.tabBar.items?[3]

                for child in dataSnapshot.children {
                    if let snapshot = child as? DataSnapshot {
                        if let chat = Chat(snapshot: snapshot) {
                            if chat.read == "false" {
                                unread += 1
                                messageTab?.badgeColor = Settings.orangeTint
                                messageTab?.badgeValue = "\(unread)"
                                UIApplication.shared.applicationIconBadgeNumber = unread
                                
                            } else if chat.read == "true"{
                                read += 1
                                if read == dataSnapshot.childrenCount {
                                    messageTab?.badgeValue = nil
                                    UIApplication.shared.applicationIconBadgeNumber = 0
                                }
                            }
                        }
                    }
                }
            })
        }
        
        Auth.auth().addStateDidChangeListener({ (auth, user) in
            if user != nil {
                Settings.currentUser = user
                self.tabBarController?.tabBar.isHidden = false
                self.signInButton.isEnabled = false
                self.signInButton.tintColor = .clear
            } else {
                Settings.currentUser = nil
                self.tabBarController?.tabBar.isHidden = true
                self.signInButton.isEnabled = true
                self.signInButton.tintColor = Settings.orangeTint
            }
        })
    }
    
    
    // MARK: - Location Methods

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.first else { return }
        
        CLGeocoder().reverseGeocodeLocation(userLocation) { (placemark, error) in
            if error != nil {
                print("Error geocoding users location: \(error?.localizedDescription ?? "")")
            }
            
            if let address = placemark?[0].postalAddress {
                Location.userLocationTown = address.subLocality
                Location.userLocationCity = address.city
                Location.userLocationCountry = address.country
                Location.userLocationAddress = address
                Location.userCLLocation = userLocation
            }
        }
        locationManager.stopUpdatingLocation()
    }
    
    
    // MARK: - Private Methods
    
    func configure(_ button: UIButton, text: String) {
        button.imageView?.contentMode = .scaleAspectFill
    }
    
    
    // MARK: - Navigation
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! RentSpaceViewController
        let button = sender as! UIButton
        vc.location = Location.userLocationCountry
        
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
    
    
    // MARK: - Action Methods

    
    @IBAction func signInButtonTapped(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(identifier: "SignInVC") as! SignInViewController
        vc.delegate = self
        present(vc, animated: true)
    }    
}


extension SpaceSelectionViewController: UpdateSignInDelegate, RegisterDelegate {
    func adjustViewAfterRegistration() {

        let frame = self.tabBarController?.tabBar.frame
        let height = frame?.size.height
        let safeArea = self.view.safeAreaLayoutGuide.layoutFrame
        let safeAreaHeightInsets = safeArea.height - self.view.frame.height
        let tabBarHeight = height! + (safeAreaHeightInsets / 2) + 2
        self.view.frame.origin.y = -tabBarHeight
    }
    
    func updateSignInButton() {
        print("")
    }
    func adjustViewForTabBar() {

        let frame = self.tabBarController?.tabBar.frame
        let height = frame?.size.height
        let safeArea = self.view.safeAreaLayoutGuide.layoutFrame
        let safeAreaHeightInsets = safeArea.height - self.view.frame.height
        let tabBarHeight = height! + (safeAreaHeightInsets / 2) + 2
        self.view.frame.origin.y = -tabBarHeight
    }
}
