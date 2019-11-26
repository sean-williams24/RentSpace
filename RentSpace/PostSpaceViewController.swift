//
//  ViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 26/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit

class PostSpaceViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    @IBOutlet var postButton: UIBarButtonItem!
    @IBOutlet var titleTextView: UITextView!
    @IBOutlet var descriptionTextView: UITextView!
    @IBOutlet var spaceTypePicker: UIPickerView!
    @IBOutlet var currencyTextView: UITextView!
    @IBOutlet var priceTextView: UITextView!
    @IBOutlet var priceRatePicker: UIPickerView!
    @IBOutlet var locationButton: UIButton!
    @IBOutlet var collectionView: UICollectionView!
    
    var spaceTypePickerContent = [String]()
    var priceRatePickerContent = [String]()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title TextView
        NSLayoutConstraint.activate([titleTextView.heightAnchor.constraint(equalToConstant: 50)])
        titleTextView.textContainerInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        
        // Description textField
        descriptionTextView.textContainerInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        
        
        // Space type picker
        spaceTypePicker.dataSource = self
        spaceTypePicker.delegate = self
        priceRatePicker.dataSource = self
        priceRatePicker.delegate = self
        spaceTypePickerContent = ["Art Studio", "Photography Studio", "Music Studio", "Desk Space"]
        priceRatePickerContent = ["Hourly", "Daily", "Weekly", "Monthly"]
        
        
        
        
    }
    
    
    //MARK: - Picker View Delegates and Data Sources
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        pickerView.subviews.forEach({
            $0.isHidden = $0.frame.height < 1.0
        })
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1 {
            return spaceTypePickerContent.count
        } else {
            return priceRatePickerContent.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 1 {
            return spaceTypePickerContent[row]
        } else {
            return priceRatePickerContent[row]
        }
    }
    
//    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
//
//    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 21, weight: .light)
        label.textAlignment = .center
        label.layer.borderWidth = .zero
        
        if pickerView.tag == 1 {
            label.text = spaceTypePickerContent[row]
        } else {
            label.text = priceRatePickerContent[row]
        }
        return label
    }
    
    
    //MARK: - Action Methods

    @IBAction func postButtonTapped(_ sender: Any) {
    }
    

    
    
    @IBAction func locationButtonTapped(_ sender: Any) {
    }
}

