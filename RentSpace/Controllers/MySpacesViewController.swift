//
//  MySpacesViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 05/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//
import FirebaseUI
import Firebase
import NVActivityIndicatorView
import UIKit


class MySpacesViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var signedOutView: UIView!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet var activityView: NVActivityIndicatorView!
    @IBOutlet var loadingLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var favouritesButton: UIBarButtonItem!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    
    
    // MARK: - Properties
    
    var mySpaces: [Space] = []
    var ref: DatabaseReference!
    fileprivate var authHandle: AuthStateDidChangeListenerHandle!
    fileprivate var refHandle: DatabaseHandle!
    var UID = ""
    var signedIn = false
    var viewingFavourites = false
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signInButton.layer.cornerRadius = Settings.cornerRadius
        favouritesButton.setTitleTextAttributes(Settings.barButtonAttributes, for: .normal)
        self.infoLabel.text = ""
        
        if #available(iOS 13.0, *) {} else {
            settingsButton.setBackgroundImage(UIImage(named: "Gear"), for: .normal, style: .plain, barMetrics: .default)
        }
        
        ref = Database.database().reference()
        
        authHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                Settings.currentUser = user
                self.mySpaces.removeAll()
                self.tableView.reloadData()
                self.signedOutView.isHidden = true
                self.favouritesButton.isEnabled = true
                self.signedIn = true
                self.UID = user!.uid
                self.loadUserSpaces()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    if self.mySpaces.isEmpty {
                        self.showLoadingUI(false, for: self.activityView, label: self.loadingLabel, text: "Loading Your Spaces...")
                        
                        if self.viewingFavourites {
                            self.showEmptySpacesInfo(for: "favourites")
                        } else {
                            self.showEmptySpacesInfo()
                        }
                    } else {
                        self.infoLabel.text = ""
                    }
                }
            } else {
                self.signedOutView.isHidden = false
                self.favouritesButton.isEnabled = false
                self.mySpaces.removeAll()
                self.tableView.reloadData()
                self.infoLabel.text = ""
                self.title = nil
                self.tabBarController?.tabBar.items?[2].title = "My Spaces"
            }
        }
        
        self.tableView.rowHeight = 150
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        
        viewingFavourites ? loadFavourites() : loadUserSpaces()
    }
    
    
    // MARK: - Helper Methods
    
    fileprivate func loadUserSpaces() {
        mySpaces.removeAll()
        tableView.reloadData()
        self.infoLabel.text = ""
        
        refHandle = ref.child("users/\(self.UID)/adverts").queryOrdered(byChild: "timestamp").observe(.value, with: { (snapShot) in
            self.showLoadingUI(true, for: self.activityView, label: self.loadingLabel, text: "Loading Your Spaces...")
            
            for child in snapShot.children {
                if let snapshot = child as? DataSnapshot,
                    let space = Space(snapshot: snapshot) {
                    self.mySpaces.insert(space, at: 0)
                }
            }
            
            self.showLoadingUI(false, for: self.activityView, label: self.loadingLabel, text: "Loading Your Spaces...")
            self.tableView.reloadData()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.mySpaces.isEmpty {
                    self.showEmptySpacesInfo()
                } else {
                    self.infoLabel.text = ""
                }
            }
        })
    }
    
    
    fileprivate func loadFavourites() {
        mySpaces.removeAll()
        tableView.reloadData()
        self.infoLabel.text = ""
        
        for favourite in Favourites.spaces {
            self.refHandle = self.ref.child("adverts/United Kingdom/\(favourite.url)").observe(.value, with: { (favSnapshot) in
                
                if let space = Space(snapshot: favSnapshot) {
                    self.mySpaces.append(space)
                }
                self.tableView.reloadData()
                
                if !self.mySpaces.isEmpty {
                    self.infoLabel.text = ""
                }
            })
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.mySpaces.isEmpty {
                self.showEmptySpacesInfo(for: "favourites")
            } else {
                self.infoLabel.text = ""
            }
        }
    }
    
    
    fileprivate func showEmptySpacesInfo(for label: String = "mySpaces") {
        if label == "favourites" {
            let attributedString = NSMutableAttributedString(string: "No Favourites Yet \n\nSave your favourite spaces by tapping their heart icon.")
            attributedString.addAttributes(Settings.infoLabelAttributes, range: NSRange(location: 0, length: 18))
            self.infoLabel.attributedText = attributedString
        } else {
            let attributedString = NSMutableAttributedString(string: "No Spaces Yet \n\nYour adverts will appear here once posted to RentSpace.")
            attributedString.addAttributes(Settings.infoLabelAttributes, range: NSRange(location: 0, length: 13))
            self.infoLabel.attributedText = attributedString
        }
    }
    
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! SettingsViewController
        vc.delegate = self
    }

    
    //MARK: - Action Methods
    
    @IBAction func favouritesButtonTapped(_ sender: Any) {
        if viewingFavourites {
            loadUserSpaces()
            favouritesButton.title = "View Favourites"
        } else {
            loadFavourites()
            favouritesButton.title = "View Spaces"
        }
        
        viewingFavourites = !viewingFavourites
    }
    
    
    @IBAction func signInButtonTapped(_ sender: Any) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "SignInVC") {
            present(vc, animated: true)
        }
    }
}


// MARK: - TableView Delegates & Datasource

extension MySpacesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return mySpaces.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 3
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "My Spaces Cell", for: indexPath) as! MySpacesTableViewCell
        let space = mySpaces[indexPath.section]
        cell.layer.borderWidth = 1
        cell.viewingFavourites = viewingFavourites
        cell.space = space
        cell.tableView = tableView
        cell.indexPath = indexPath
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "AdvertDetailsVC") as! AdvertDetailsViewController
        vc.space = mySpaces[indexPath.section]
        
        if viewingFavourites {
            vc.editingMode = false
            vc.arrivedFromFavourites = true
        } else {
            vc.editingMode = true
        }
        show(vc, sender: self)
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return viewingFavourites
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let space = mySpaces[indexPath.section]
        
        if editingStyle == .delete {
            let ac = UIAlertController(title: "Remove Favourite", message: "Are you sure you wish to remove this space from your favourites?", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.ref.child("users/\(self.UID)/favourites/\(space.key)").removeValue()
                
                for (i, spaceToDelete) in self.mySpaces.enumerated().reversed() {
                    if space.key == spaceToDelete.key {
                        self.mySpaces.remove(at: i)
                    }
                }
                tableView.reloadData()
                
                if self.viewingFavourites && self.mySpaces.isEmpty {
                    self.showEmptySpacesInfo(for: "favourites")
                }
            }))
            
            ac.addAction(UIAlertAction(title: "Cancel", style: .default))
            present(ac, animated: true)
        }
    }
}

extension MySpacesViewController: userDidSignOutDelegate {
    func removeUserData() {
        mySpaces.removeAll()
        tableView.reloadData()
        let messageTab = self.tabBarController?.tabBar.items?[3]
        messageTab?.badgeValue = nil
    }
}


