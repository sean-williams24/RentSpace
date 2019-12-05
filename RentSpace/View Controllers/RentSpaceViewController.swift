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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureDatabase()
        storageRef = Storage.storage().reference()

        let locale = Locale.current
        print(locale.regionCode!)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(adverts)
        tableView.reloadData()
    }
    

    
    // MARK: - Config

    func configureDatabase() {
        ref = Database.database().reference()
        _refHandle = ref.child("adverts/UK/Art Studio").observe(.childAdded, with: { (snapshot) in
            self.adverts.append(snapshot)
            self.tableView.insertRows(at: [IndexPath(row: self.adverts.count - 1, section: 0)], with: .automatic)
            print(self.adverts)
        })
        
    }
    
    deinit {
        ref.child("adverts").removeObserver(withHandle: _refHandle)
    }

}


// MARK: - TableView Delegates & Datasource


extension RentSpaceViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        adverts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Advert Cell", for: indexPath) as! AdvertTableViewCell
        
        let advertSnapshot = adverts[indexPath.row]
        let advert = advertSnapshot.value as! [String : Any]
        cell.descriptionLabel.text = advert[Advert.description] as? String
        cell.categoryLabel.text = advert[Advert.category] as? String
        cell.locationLabel.text = advert[Advert.address] as? String
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
