//
//  ViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 26/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import Firebase
import UIKit

class PostSpaceViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UINavigationControllerDelegate {
    
    
    @IBOutlet var postButton: UIBarButtonItem!
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var currencyTextField: UITextField!
    @IBOutlet var priceTextField: UITextField!
    @IBOutlet var descriptionTextView: UITextView!
    @IBOutlet var spaceTypePicker: UIPickerView!
    @IBOutlet var priceRatePicker: UIPickerView!
    @IBOutlet var locationButton: UIButton!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var addPhotosButton: UIButton!
    @IBOutlet var collectionViewHeightConstraint: NSLayoutConstraint!
    
    var spaceTypePickerContent = [String]()
    var priceRatePickerContent = [String]()
    var images = [Image]()
    
    let itemsPerRow: CGFloat = 5
    let collectionViewInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    var ref: DatabaseReference!
    var category = ""
    var priceRate = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title textfield
        let leftPadView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: titleTextField.frame.height))
        titleTextField.leftView = leftPadView
        titleTextField.leftViewMode = .always
        titleTextField.attributedPlaceholder = NSAttributedString(string: "Title", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        // Description textView
        descriptionTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 4, right: 4)
        descriptionTextView.textColor = .lightGray
        descriptionTextView.text = "Describe your studio space here..."
        descriptionTextView.delegate = self
        
        // Location Button
        locationButton.layer.cornerRadius = 15
        
        // Space type picker
        spaceTypePicker.dataSource = self
        spaceTypePicker.delegate = self
        priceRatePicker.dataSource = self
        priceRatePicker.delegate = self
        spaceTypePickerContent = ["Art Studio", "Photography Studio", "Music Studio", "Desk Space"]
        priceRatePickerContent = ["Hourly", "Daily", "Weekly", "Monthly"]
        
        // Price textFields
        let leftPadView1 = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: titleTextField.frame.height))
        currencyTextField.leftView = leftPadView1
        currencyTextField.leftViewMode = .always
        currencyTextField.attributedPlaceholder = NSAttributedString(string: "Currency", attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray])
        
        let leftPadView2 = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: titleTextField.frame.height))

        priceTextField.leftView = leftPadView2
        priceTextField.leftViewMode = .always
        priceTextField.attributedPlaceholder = NSAttributedString(string: "Price", attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray])

        if UIDevice.current.userInterfaceIdiom == .pad {
            collectionViewHeightConstraint.constant = 420
        }
        
        // Keyboard dismissal
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        view.addGestureRecognizer(tap)
        
        ref = Database.database().reference()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadUDImages()
        collectionView.reloadData()
        
        let email = UserDefaults.standard.string(forKey: "Email")
        locationButton.titleLabel?.text = "  \(email ?? "Contact & Address ->")"
        if email == "" {
            locationButton.titleLabel?.text = "  Contact & Address ->"
        }
        
        // Add Photos Button
        if images.isEmpty == false {
            UIView.animate(withDuration: 0.5) {
                self.addPhotosButton.imageView?.alpha = 0.1
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
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
                print("Data could not be decoded: \(error)")
            }
        }
    }
    
    

    
    
    //MARK: - Picker View Delegates and Data Sources
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // Hide borders of picker view
//        pickerView.subviews.forEach({
//            $0.isHidden = $0.frame.height < 1.0
//        })
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
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .light)
        label.textAlignment = .center
        label.textColor = .systemPurple
        label.layer.borderWidth = .zero
        
        if pickerView.tag == 1 {
            label.text = spaceTypePickerContent[row]
        } else {
            label.text = priceRatePickerContent[row]
        }
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        view.endEditing(true)
        
        if pickerView.tag == 1 {
            category = spaceTypePickerContent[row]
        } else {
            priceRate = priceRatePickerContent[row]
        }
    }
    

    
    //MARK: - Action Methods

    @IBAction func postButtonTapped(_ sender: Any) {
        let price = currencyTextField.text! + priceTextField.text! + priceRate
        
        let data = [Advert.title: titleTextField.text!,
                    Advert.description: descriptionTextView.text!,
                    Advert.category: category,
                    Advert.price: price,
                    Advert.phone: UserDefaults.standard.string(forKey: "Phone"),
                    Advert.email: UserDefaults.standard.string(forKey: "Email"),
                    Advert.address: UserDefaults.standard.string(forKey: "Address")
        ]
        ref.child("adverts").childByAutoId().setValue(data)
        
    }
    
    @IBAction func addPhotosButtonTapped(_ sender: Any) {
        
    }
    
}


//MARK: - Text Delegates

extension PostSpaceViewController: UITextFieldDelegate, UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if descriptionTextView.text == "Describe your studio space here..." {
            descriptionTextView.text = ""
            descriptionTextView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if descriptionTextView.text == "" {
            descriptionTextView.text = "Describe your studio space here..."
            descriptionTextView.textColor = .lightGray
        }
        descriptionTextView.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
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

//MARK: - Collection View Flow Layout Delegates

extension PostSpaceViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = collectionViewInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
      return collectionViewInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
      return collectionViewInsets.left
    }
    
}
