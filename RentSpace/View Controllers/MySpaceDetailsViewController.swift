//
//  MySpaceViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 05/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import MapKit
import UIKit

class MySpaceDetailsViewController: UIViewController {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var descriptionTextView: UITextView!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var locationIcon: UIImageView!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var pageController: UIPageControl!
    @IBOutlet var emailButton: UIButton!
    @IBOutlet var phoneButton: UIButton!
    @IBOutlet var messagesButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

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

    @IBAction func emailButtonTapped(_ sender: Any) {
    }
    
    @IBAction func phoneButtonTapped(_ sender: Any) {
    }
    
}
