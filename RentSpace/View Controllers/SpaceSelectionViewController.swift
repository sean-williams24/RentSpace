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
    @IBOutlet var stackView: UIStackView!
    @IBOutlet weak var musicImageview: UIImageView!
    @IBOutlet weak var photographyImageview: UIImageView!
    @IBOutlet weak var deskImageview: UIImageView!
    
    
    // MARK: - Properties
    
    var locationManager: CLLocationManager!
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure(artButton, text: "Art")
        configure(photographyButton, text: "Photography")
        configure(musicButton, text: "Music")
        configure(deskButton, text: "Desk Space")
        
        if #available(iOS 13.0, *) {
            photographyImageview.image = UIImage(systemName: "camera")
            musicImageview.image = UIImage(systemName: "music.mic")
            deskImageview.image = UIImage(systemName: "studentdesk")
        } else {
            photographyImageview.image = UIImage(named: "Photography Studio")
            musicImageview.image = UIImage(named: "Music Studio")
            deskImageview.image = UIImage(named: "Desk Space")
        }
        
        if #available(iOS 13.0, *) {
            self.tabBarController?.tabBar.items?[0].image = UIImage(systemName: "eye")
            self.tabBarController?.tabBar.items?[0].selectedImage = UIImage(systemName: "eye")
            self.tabBarController?.tabBar.items?[1].image = UIImage(systemName: "studentdesk")
            self.tabBarController?.tabBar.items?[1].selectedImage = UIImage(systemName: "studentdesk")
            self.tabBarController?.tabBar.items?[2].image = UIImage(systemName: "person")
            self.tabBarController?.tabBar.items?[2].selectedImage = UIImage(systemName: "person")
            self.tabBarController?.tabBar.items?[3].image = UIImage(systemName: "bubble.left.and.bubble.right")
            self.tabBarController?.tabBar.items?[3].selectedImage = UIImage(systemName: "bubble.left.and.bubble.right")
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
            if error != nil || granted == false {

                if !UserDefaults.standard.bool(forKey: "launchedBefore") {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Notifications Off", message: "\nWithout notifications turned on you may miss messages from studios or customers. Notifications can be turned on in the Settings App.")
                    }
                }
            }
        }
        
        // Get saved location - store to Location class
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
        
        // Request location authorization on first app launch - if denied, set location to london
        if !UserDefaults.standard.bool(forKey: "launchedBefore") {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }
        
        let registerVC = storyboard?.instantiateViewController(withIdentifier: "RegisterVC") as! RegisterViewController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        registerVC.delegate = self
        appDelegate.delegate = self
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        for constraint in self.view.constraints {
            if constraint.identifier == "stackViewBottom" {
                constraint.constant = 3
            }
        }
        
        Auth.auth().addStateDidChangeListener({ (auth, user) in
            if user != nil {
                Settings.currentUser = user
                self.tabBarController?.tabBar.isHidden = false
                self.signInButton.isEnabled = false
                self.signInButton.tintColor = .clear
                self.checkForMessages()

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
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            print("No location access, denied or restricted")
            if !UserDefaults.standard.bool(forKey: "launchedBefore") {
                showAlert(title: "Location Services Disabled", message: "Location set to London, this can be changed by tapping the London button on the next screen. Location services can be enabled at anytime from the Apple Settings app.")
            }
            
            CLGeocoder().geocodeAddressString("London") { (placemarks, error) in
                if error != nil {
                    self.showAlert(title: "Location Error", message: "Please set a new search location by tapping the London button on the next screen")
                }
                
                if let address = placemarks?[0].postalAddress {
                    Location.userLocationTown = address.subLocality
                    Location.userLocationCity = address.city
                    Location.userLocationCountry = address.country
                    Location.userLocationAddress = address
                    if let location = placemarks?[0].location {
                        Location.userCLLocation = location
                    }
                }
            }
        case .notDetermined:
            print("Not determined")
        
        case .authorizedAlways, .authorizedWhenInUse :
            print("Access")
            locationManager.startUpdatingLocation()
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Private Methods
    
    func configure(_ button: UIButton, text: String) {
        button.imageView?.contentMode = .scaleAspectFill
    }
    
    
    fileprivate func checkForMessages() {
        if let UID = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            
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
        let vc = storyboard?.instantiateViewController(withIdentifier: "SignInVC") as! SignInViewController
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
        let tabBarHeight = height! + (safeAreaHeightInsets) + 2

        for constraint in self.view.constraints {
            if constraint.identifier == "stackViewBottom" {
                constraint.constant = tabBarHeight
            }
        }
        stackView.layoutIfNeeded()
    }
}
