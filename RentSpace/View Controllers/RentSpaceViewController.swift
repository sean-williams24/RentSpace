//
//  RentSpaceViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 27/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import Firebase
import UIKit

class RentSpaceViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    var ref: DatabaseReference!
    var storageRef: StorageReference!
    fileprivate var _refHandle: DatabaseHandle!
    
    var adverts: [DataSnapshot] = []
    var chosenCategory = ""
    var location = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDatabase()
        storageRef = Storage.storage().reference()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    

    
    // MARK: - Config

    func configureDatabase() {
        ref = Database.database().reference()
        _refHandle = ref.child("adverts/\(location)/\(chosenCategory)").observe(.childAdded, with: { (snapshot) in
            self.adverts.append(snapshot)
            self.tableView.insertSections(IndexSet(integer: self.adverts.count - 1), with: .automatic)
        })
        
    }
    
    deinit {
        ref.child("adverts").removeObserver(withHandle: _refHandle)
    }

}


// MARK: - TableView Delegates & Datasource


extension RentSpaceViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return adverts.count
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Advert Cell", for: indexPath) as! AdvertTableViewCell
        cell.layer.cornerRadius = 8
        cell.layer.borderWidth = 1
        
        let advertSnapshot = adverts[indexPath.section]
        let advert = advertSnapshot.value as! [String : Any]

        // Format location label from address data
        var location = ""
        let city = advert[Advert.city] as? String ?? ""
        let subAdminArea = advert[Advert.subAdminArea] as? String ?? ""
        let town = advert[Advert.town] as? String ?? ""
        
        if city == subAdminArea {
            location = "\(town), \(city)"
        } else {
            location = "\(town), \(city), \(subAdminArea)"
            if town == "" {
                location = "\(city), \(subAdminArea)"
            }
        }
        if location == ", " {
            location = advert[Advert.address] as? String ?? ""
        }
        
        // Populate cell content from downloaded advert data from Firebase
        let title = advert[Advert.title] as? String
        cell.titleLabel.text = title?.uppercased()
        cell.descriptionLabel.text = advert[Advert.description] as? String
        cell.categoryLabel.text = advert[Advert.category] as? String
        cell.locationLabel.text = location
        cell.priceLabel.text = advert[Advert.price] as? String
        if let imageURLsDict = advert[Advert.photos] as? [String : String] {
            if let imageURL = imageURLsDict["image 0"] {
            
                Storage.storage().reference(forURL: imageURL).getData(maxSize: INT64_MAX) { (data, error) in
                    guard error == nil else {
                        print("error downloading: \(error?.localizedDescription ?? error.debugDescription)")
                        return
                    }
                    let cellImage = UIImage.init(data: data!, scale: 0.1)
                    
                    // Check to see if cell is still on screen, if so update cell
                    if cell == tableView.cellForRow(at: indexPath) {
                        DispatchQueue.main.async {
                            cell.customImageView?.image = cellImage
                            cell.setNeedsLayout()
                        }
                    }
                }
                
            }
        }
        return cell
    }
}
