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
    
    @IBOutlet var artButton: UIButton!
    @IBOutlet var photographyButton: UIButton!
    @IBOutlet var musicButton: UIButton!
    @IBOutlet var deskButton: UIButton!
    @IBOutlet var signInButton: UIBarButtonItem!
    
    var locationManager: CLLocationManager!
    var handle: AuthStateDidChangeListenerHandle!
    var chatsHandle: DatabaseHandle!
    
    // MARK: - Life Cycle
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
        
        handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            if user != nil {
                Settings.currentUser = user
                self.tabBarController?.tabBar.isHidden = false
                self.signInButton.isEnabled = false
                self.signInButton.tintColor = .clear
                
                let frame = self.tabBarController?.tabBar.frame
                let height = frame?.size.height
                let safeArea = self.view.safeAreaLayoutGuide.layoutFrame
                let safeAreaHeightInsets = safeArea.height - self.view.frame.height
                let tabBarHeight = height! + (safeAreaHeightInsets / 2) + 2
                self.view.frame.origin.y = -tabBarHeight

            } else {
                self.tabBarController?.tabBar.isHidden = true
                self.signInButton.isEnabled = true
                self.signInButton.tintColor = Settings.orangeTint
            }
        })
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
            if error != nil {
                DispatchQueue.main.async {
                    self.showAlert(title: "Notifications", message: "Without notifications on you may miss messages from customers. Notifications can be turned on in the Settings App.")
                }
            }
        }
        
        if let UID = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            
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
            chatsHandle = ref.child("users/\(UID)/chats").observe(.value, with: { (dataSnapshot) in
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        configure(artButton, text: "Art")
        configure(photographyButton, text: "Photography")
        configure(musicButton, text: "Music")
        configure(deskButton, text: "Desk Space")
                
        let savedLocation = UserDefaults.standard.string(forKey: "Location")
        let savedLocationPostcode = UserDefaults.standard.string(forKey: "LocationPostcode") ?? ""
        
        if let savedLocation = savedLocation {
            Constants.savedLocationExists = true
            CLGeocoder().geocodeAddressString(savedLocation + " " + savedLocationPostcode) { (placemark, error) in
                if error != nil {
                    print("Error geocoding users location: \(error?.localizedDescription ?? "")")
                }
                if let location = placemark?[0].location {
                    print(placemark?[0] as Any)
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
        //        button.imageView?.layer.cornerRadius = 8
        //        button.layer.borderWidth = 0.2
        //        button.layer.borderColor = UIColor.white.cgColor
        //        button.backgroundColor = .clear
        //        button.layer.shadowColor = UIColor.darkGray.cgColor
        //        button.layer.shadowOpacity = 1
        //        button.layer.shadowRadius = 4
        //        button.layer.shadowOffset = CGSize(width: 1, height: 2)
        
        //        let label = UILabel()
        //        label.translatesAutoresizingMaskIntoConstraints = false
        //      label.font = UIFont.systemFont(ofSize: 28, weight: .light)
        //    label.textColor = .white
        //  label.text = text
        //label.textAlignment = .center
        //button.addSubview(label)
        
        NSLayoutConstraint.activate([
            //            label.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            //            label.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 28),
            //            label.topAnchor.constraint(equalToSystemSpacingBelow: button.topAnchor, multiplier: 0),
            //            label.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            //            label.centerYAnchor.constraint(equalTo: button.centerYAnchor)
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
    
    
    // MARK: - Action Methods

    
    @IBAction func signInButtonTapped(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(identifier: "SignInVC") as! SignInViewController
        present(vc, animated: true)
    }
    
    
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        //        let vc = storyboard?.instantiateViewController(identifier: "RentSpaceVC") as! RentSpaceViewController
        
    }
    
}


extension UIImage {
    
    func alpha(_ value:CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
