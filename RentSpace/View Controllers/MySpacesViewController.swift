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
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var signedOutView: UIView!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet var activityView: NVActivityIndicatorView!
    @IBOutlet var loadingLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var favouritesButton: UIBarButtonItem!
    
    var mySpaces: [DataSnapshot] = []
    var ref: DatabaseReference!
    fileprivate var authHandle: AuthStateDidChangeListenerHandle!
    fileprivate var refHandle: DatabaseHandle!
    var UID = ""
    
    
    // MARK: - Life Cycle
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let displayName = Auth.auth().currentUser?.displayName {
            self.title = displayName
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        signInButton.layer.cornerRadius = Settings.cornerRadius
        
        authHandle = Auth.auth().addStateDidChangeListener { (auth, user) in

            if user != nil {
                self.showLoadingUI(true, for: self.activityView, label: self.loadingLabel)

                self.signedOutView.isHidden = true
                Settings.currentUser = user
                
                self.ref = Database.database().reference()
                self.UID = user!.uid
                self.refHandle = self.ref.child("users/\(self.UID)/adverts").observe(.value, with: { (snapShot) in
                    self.mySpaces.removeAll()
                    self.tableView.reloadData()
                    
                    for child in snapShot.children {
                        if let advertSnapshot = child as? DataSnapshot {
                            self.mySpaces.append(advertSnapshot)
                        }
                    }
                    
                    self.showLoadingUI(false, for: self.activityView, label: self.loadingLabel)
                    self.tableView.reloadData()
                    
                    let indexPath = IndexPath(row: 0, section: self.tableView.numberOfSections - 1)
                    guard let cell = self.tableView.cellForRow(at: indexPath) as? MySpacesTableViewCell else { return }
                    cell.activityView.startAnimating()
                })

                self.title = Settings.currentUser?.email
                if let displayName = Auth.auth().currentUser?.displayName {
                    self.title = displayName
                }
                
                if self.mySpaces.isEmpty {
                    self.infoLabel.text = "Your adverts will appear here once posted to RentSpace."
                } else {
                    self.infoLabel.text = ""
                }
                
            } else {
                self.signedOutView.isHidden = false
                self.mySpaces.removeAll()
                self.tableView.reloadData()
                self.title = nil
                self.tabBarController?.tabBar.items?[2].title = "My Spaces"
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        Auth.auth().removeStateDidChangeListener(authHandle)
//        ref.child("users/\(UID)/adverts").removeObserver(withHandle: refHandle)

    }
    
    deinit {
//        Auth.auth().removeStateDidChangeListener(authHandle)
    }
    
    //MARK: - Action Methods
    
    
    @IBAction func favouritesButtonTapped(_ sender: Any) {
        
        
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
        return 5
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "My Spaces Cell", for: indexPath) as! MySpacesTableViewCell
        cell.layer.cornerRadius = 8
        cell.layer.borderWidth = 1
        
        let advertSnapshot = mySpaces[indexPath.section]
        let advert = advertSnapshot.value as! [String : Any]
        
        // Populate cell content from downloaded advert data from Firebase
        let title = advert[Advert.title] as? String
        cell.titleLabel.text = title?.uppercased()
        cell.descriptionLabel.text = advert[Advert.description] as? String
        cell.categoryLabel.text = advert[Advert.category] as? String
        cell.locationLabel.text = formatAddress(for: advert)
        
        if let price = advert[Advert.price] as? String, let priceRate = advert[Advert.priceRate] as? String {
            cell.priceLabel.text = "£\(price) \(priceRateFormatter(rate: priceRate))"
        }
        
        if let imageURLsDict = advert[Advert.photos] as? [String : String] {
            if let imageURL = imageURLsDict["image 1"] {
            
                Storage.storage().reference(forURL: imageURL).getData(maxSize: INT64_MAX) { (data, error) in
                    guard error == nil else {
                        print("error downloading: \(error?.localizedDescription ?? error.debugDescription)")
                        return
                    }
                    let cellImage = UIImage.init(data: data!, scale: 0.1)
                    cell.activityView.stopAnimating()

                    // Check to see if cell is still on screen, if so update cell
                    if cell == tableView.cellForRow(at: indexPath) {
                        DispatchQueue.main.async {
                            cell.customImageView.alpha = 1
                            cell.customImageView?.image = cellImage
                            cell.setNeedsLayout()
                        }
                    }
                }
                
            }
        } else {
            cell.customImageView.image = UIImage(named: "003-desk")
            cell.customImageView.alpha = 1
            cell.activityView.stopAnimating()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(identifier: "AdvertDetailsVC") as! AdvertDetailsViewController
        vc.advertSnapshot = mySpaces[indexPath.section]
        vc.editingMode = true
        show(vc, sender: self)
    }
    
    
    
}


