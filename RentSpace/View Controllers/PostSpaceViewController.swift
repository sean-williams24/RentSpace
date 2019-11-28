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
    @IBOutlet var titleTextField: UITextField!
    
    
    @IBOutlet var descriptionTextView: UITextView!
    @IBOutlet var spaceTypePicker: UIPickerView!
    @IBOutlet var currencyTextView: UITextView!
    @IBOutlet var priceTextView: UITextView!
    @IBOutlet var priceRatePicker: UIPickerView!
    @IBOutlet var locationButton: UIButton!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var addPhotosButton: UIButton!
    
    var spaceTypePickerContent = [String]()
    var priceRatePickerContent = [String]()
    var images = [Image]()
    
    let itemsPerRow = 5

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let leftPadView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: titleTextField.frame.height))
        titleTextField.leftView = leftPadView
        titleTextField.leftViewMode = .always
        
        // Title TextView
//        NSLayoutConstraint.activate([titleTextView.heightAnchor.constraint(equalToConstant: 50)])
//        titleTextView.textContainerInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        
        // Description textField
//        descriptionTextView.textContainerInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        
        // Location Button
        locationButton.layer.cornerRadius = 15
        
        // Space type picker
        spaceTypePicker.dataSource = self
        spaceTypePicker.delegate = self
        priceRatePicker.dataSource = self
        priceRatePicker.delegate = self
        spaceTypePickerContent = ["Art Studio", "Photography Studio", "Music Studio", "Desk Space"]
        priceRatePickerContent = ["Hourly", "Daily", "Weekly", "Monthly"]
        
        
//        loadUDImages()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadUDImages()
        collectionView.reloadData()
    }
    
    
    //MARK: - Private Methods
    
    func getDocumentsDirectory() -> URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return path[0]
    }
    
    fileprivate func loadUDImages() {
        if let imageData = UserDefaults.standard.data(forKey: "Images") {
            do {
                let jsonDecoder = JSONDecoder()
                images = try jsonDecoder.decode([Image].self, from: imageData)
            } catch {
                print("Data could not be decoder: \(error)")
            }
        }
    }
    
    //MARK: - Picker View Delegates and Data Sources
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // Hide borders of picker view
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
    
    @IBAction func addPhotosButtonTapped(_ sender: Any) {
        
    }
    
    
    
    @IBAction func locationButtonTapped(_ sender: Any) {
    }
}



// MARK: - Collection view delegates 


extension PostSpaceViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PreviewPhotoCollectionViewCell
        
        let image = images[indexPath.item]
        let imageFile = getDocumentsDirectory().appendingPathComponent(image.imageName)
        cell.imageView.image = UIImage(contentsOfFile: imageFile.path)
        
        return cell
    }
    
    
    
}

extension PostSpaceViewController: UICollectionViewDelegateFlowLayout {
    
    
}
