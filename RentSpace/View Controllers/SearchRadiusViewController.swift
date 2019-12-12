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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Search Location"
        locationButton.setTitle("Current Location: \(currentLocation)", for: .normal)

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func locationButtonTapped(_ sender: Any) {
    }
    
    @IBAction func distanceSliderChanged(_ sender: Any) {
    }
}
