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

    var ref: DatabaseReference!
    fileprivate var _refHandle: DatabaseHandle!
    
    var adverts: [DataSnapshot] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureDatabase()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(adverts)
    }
    

    
    // MARK: - Config

    func configureDatabase() {
        ref = Database.database().reference()
        _refHandle = ref.child("adverts").observe(.childAdded, with: { (snapshot) in
            self.adverts.append(snapshot)
            print(self.adverts)
        })
        
    }

}


// MARK: - TableView Delegates & Datasource


extension RentSpaceViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        adverts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Advert Cell", for: indexPath) as! AdvertTableViewCell
     
        
        return cell
    }
    
    
    
}
