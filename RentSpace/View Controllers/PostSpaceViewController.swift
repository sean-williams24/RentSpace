//
//  ViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 26/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//
import FirebaseAuth
import Firebase
import UIKit
import Contacts

class PostSpaceViewController: UIViewController, UINavigationControllerDelegate {
    
    
    @IBOutlet var postButton: UIBarButtonItem!
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var priceTextField: UITextField!
    @IBOutlet var descriptionTextView: UITextView!
    @IBOutlet var spaceTypePicker: UIPickerView!
    @IBOutlet var priceRatePicker: UIPickerView!
    @IBOutlet var locationButton: UIButton!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var addPhotosButton: UIButton!
    @IBOutlet var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var activityView: UIActivityIndicatorView!
    @IBOutlet var uploadView: UIView!
    @IBOutlet var signedOutView: UIView!
    @IBOutlet var signInButton: UIButton!
    
    var spaceTypePickerContent = [String]()
    var priceRatePickerContent = [String]()
    var images = [Image]()
    var imagesToUpload: [Image] = []
    
    let itemsPerRow: CGFloat = 5
    let collectionViewInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    var ref: DatabaseReference!
    var storageRef: StorageReference!
    fileprivate var handle: AuthStateDidChangeListenerHandle!
    var category = "Art Studio"
    var priceRate = "Hourly"
    let descriptionViewPlaceholder = "Describe your studio space here..."
    var location = ""
 
    
    //MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()

        if UIDevice.current.userInterfaceIdiom == .pad {
            collectionViewHeightConstraint.constant = 420
        }
        
        // Keyboard dismissal
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        view.addGestureRecognizer(tap)
        
        ref = Database.database().reference()
        storageRef = Storage.storage().reference()


    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
        imagesToUpload = []
        
        handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            if user == nil {
//                let vc = self.storyboard?.instantiateViewController(identifier: "SignInVC") as! SignInViewController
//                self.present(vc, animated: true)
                self.signedOutView.isHidden = false
                self.postButton.isEnabled = false
            } else {
                self.signedOutView.isHidden = true
                self.postButton.isEnabled = true
                Settings.currentUser = user
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadUDImages()
        collectionView.reloadData()

        let email = UserDefaults.standard.string(forKey: "Email") ?? ""
        let postcode = UserDefaults.standard.string(forKey: "PostCode") ?? ""
        
        locationButton.titleLabel?.text = " \(postcode) / \(email)"
        if email == "" || postcode == "" {
            locationButton.titleLabel?.text = "  Contact & Address"
        }
        
        location = UserDefaults.standard.string(forKey: "Country") ?? ""
        
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
        Auth.auth().removeStateDidChangeListener(handle)
    }
    
  
    
    //MARK: - Private Methods
    
    
     fileprivate func configureUI() {
         // Title textfield
         let leftPadView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: titleTextField.frame.height))
         titleTextField.leftView = leftPadView
         titleTextField.leftViewMode = .always
         titleTextField.attributedPlaceholder = NSAttributedString(string: "Title", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
         
         // Description textView
         descriptionTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 4, right: 4)
         descriptionTextView.textColor = .lightGray
         descriptionTextView.text = descriptionViewPlaceholder
         descriptionTextView.delegate = self
         
         // Location Button
         let disclosure = UITableViewCell()
         disclosure.frame = locationButton.bounds
         disclosure.accessoryType = .disclosureIndicator
         disclosure.isUserInteractionEnabled = false
         locationButton.addSubview(disclosure)
         locationButton.titleLabel?.textAlignment = .center
         NSLayoutConstraint.activate([(locationButton.titleLabel?.widthAnchor.constraint(equalToConstant: locationButton.frame.width))!])
         
         // Space type picker
         spaceTypePicker.dataSource = self
         spaceTypePicker.delegate = self
         priceRatePicker.dataSource = self
         priceRatePicker.delegate = self
         spaceTypePickerContent = ["Art Studio", "Photography Studio", "Music Studio", "Desk Space"]
         priceRatePickerContent = ["Hourly", "Daily", "Weekly", "Monthly", "Annually"]
         
         // Price textFields
         //        var paddingWidth: CGFloat = 15
         //        if Constants.userLocation == "United Kingdom" {
         //            currencyTextField.text = "£"
         //            paddingWidth = 35
         //        } else if Constants.userLocation == "United States" || Constants.userLocation == "Australia" || Constants.userLocation == "Canada" {
         //            currencyTextField.text = "$"
         //            paddingWidth = 35
         //        }
         
         //        let leftPadView1 = UIView(frame: CGRect(x: 0, y: 0, width: paddingWidth, height: currencyTextField.frame.height))
         //        currencyTextField.leftView = leftPadView1
         //        currencyTextField.leftViewMode = .always
         //        currencyTextField.attributedPlaceholder = NSAttributedString(string: "Currency", attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray])
         
//         let leftPadView2 = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: titleTextField.frame.height))
//         priceTextField.leftView = leftPadView2
//         priceTextField.leftViewMode = .always
         priceTextField.attributedPlaceholder = NSAttributedString(string: "Price", attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray])
        
        signInButton.layer.cornerRadius = 5
        uploadView.isHidden = true
     }
    
    func getDocumentsDirectory() -> URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return path[0]
    }
    
    fileprivate func loadUDImages() {
        if let imageData = UserDefaults.standard.data(forKey: "Images") {
            do {
                let jsonDecoder = JSONDecoder()
                images = try jsonDecoder.decode([Image].self, from: imageData)
                print("User defaults images loaded: \(images.count)")
            } catch {
                print("Data could not be decoded: \(error)")
            }
        }
    }
    
    func priceRateFormatter(rate: String) -> String {
        switch rate {
        case "Hourly":
            return "An Hour"
        case "Daily":
            return "Per Day"
        case "Weekly":
            return "Per Week"
        case "Monthly":
            return "Per Month"
        case "Annually":
            return "Per Year"
        default:
            return "Per Hour"
        }
    }
    
    
    
    fileprivate func uploadToFirebase(_ imageURLs: [String : String]? = nil) {
        // Package advert into data object
        let price = "\(self.priceTextField.text!) \(self.priceRateFormatter(rate: self.priceRate))"
        var descriptionText = descriptionTextView.text
        if descriptionText == descriptionViewPlaceholder {
            descriptionText = ""
        }
        
        let data: [String : Any] = [Advert.title: self.titleTextField.text!,
                                    Advert.description: descriptionText as Any,
                                    Advert.category: self.category,
                                    Advert.price: price,
                                    Advert.phone: UserDefaults.standard.string(forKey: "Phone") as Any,
                                    Advert.email: UserDefaults.standard.string(forKey: "Email") as Any,
                                    Advert.address: UserDefaults.standard.string(forKey: "Address") as Any,
                                    Advert.postCode: UserDefaults.standard.string(forKey: "PostCode") as Any,
                                    Advert.city: UserDefaults.standard.string(forKey: "City") as Any,
                                    Advert.subAdminArea: UserDefaults.standard.string(forKey: "SubAdminArea") as Any,
                                    Advert.country: UserDefaults.standard.string(forKey: "Country") as Any,
                                    Advert.town: UserDefaults.standard.string(forKey: "Town") as Any,
                                    Advert.photos: imageURLs as Any,
                                    Advert.viewOnMap: UserDefaults.standard.bool(forKey: "ViewOnMap")
        ]
        
        // Write to Adverts firebase path
        let UID = Settings.currentUser?.uid
        let uniqueID = UUID().uuidString
        let path = "adverts/\(self.location)/\(self.category)/\(UID!)-\(uniqueID)"
        self.ref.child(path).setValue(data) { (error, reference) in
            if error != nil {
                print(error?.localizedDescription as Any)
                // TODO: - HANDLE ERROR
                return
            }
            
            self.ref.child("users/\(UID!)/adverts/\(uniqueID)").setValue(data) { (userError, ref) in
                if userError != nil {
                    print(userError as Any)
                }
                
                print("Upload Complete")
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
                
                self.titleTextField.text = ""
                self.priceTextField.text = ""
                self.locationButton.setTitle("Contact & Address", for: .normal)
                self.configureUI()
                self.images = []
                self.imagesToUpload = []
                self.collectionView.reloadData()
                
                // TODO - show modal VC with conformtiaon of upload - link to ad in 'my ads' or dismiss to post another
                let vc = self.storyboard?.instantiateViewController(identifier: "PostConfirmationVC") as! PostConfirmationViewController
                self.present(vc, animated: true)
            }

        }
        

    }
    
    func postAdvert() {
        uploadView.isHidden = false
        if imagesToUpload.isEmpty {
            uploadToFirebase()
        } else {
            uploadAdvertWithImagesToFirebase { (imageURLs) in
                self.uploadToFirebase(imageURLs)
            }
        }
    }

    
    func uploadAdvertWithImagesToFirebase(completion: @escaping ([String : String]) -> ()) {
        // Upload images to Firbebase storage
        var imageURLs: [String : String] = [:]
        var uploadedImagesCount = 0
        print("images to upload \(imagesToUpload.count)")
        for image in imagesToUpload {
            let imageFile = getDocumentsDirectory().appendingPathComponent(image.imageName)
            let UIImageVersion = UIImage(contentsOfFile: imageFile.path)
            if let imageData = UIImageVersion?.jpegData(compressionQuality: 0.2) {
                let imagePath = "advertPhotos/\(Double(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
                let metaData = StorageMetadata()
                metaData.contentType = "image/jpeg"
                
                storageRef!.child(imagePath).putData(imageData, metadata: metaData) { (metadata, error) in
                    if let error = error {
                        print("Error uploading: \(error)")
                        return
                    }
                    
                    // Get URL for photo and add to dictionary
                    let url = self.storageRef!.child((metadata?.path)!).description
                    imageURLs["image \(uploadedImagesCount)"] = url
                    uploadedImagesCount += 1
                    print("uploadoaded images count: \(uploadedImagesCount)")
                    
                    // Call completion handler once all images are uploaded, passing in imageURLs
                    if uploadedImagesCount == self.imagesToUpload.count {
                        completion(imageURLs)
                    }
                }
            }
        }
    }
    
    
    deinit {

        print("deinit called")
    }

    
    //MARK: - Action Methods

    @IBAction func postButtonTapped(_ sender: Any) {
        if titleTextField.text == "" {
            titleTextField.attributedPlaceholder = NSAttributedString(string: "Title", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemPink])
            if priceTextField.text == "" {
                priceTextField.attributedPlaceholder = NSAttributedString(string: "Price", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemPink])
            }
            return
        }
        
        guard priceTextField.text != "" else {
            showAlert(title: "Please enter a price...", message: nil)
            priceTextField.attributedPlaceholder = NSAttributedString(string: "Price", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemPink])
            return
        }
        
        guard location != "" else {
            showAlert(title: "Please set a location for your space.", message: nil)
            return
        }
        
        if imagesToUpload.isEmpty {
            let ac = UIAlertController(title: "No photos selected", message: "Are you sure you wish to proceed without a photo?", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Post Ad", style: .default, handler: { _ in
                self.postAdvert()
            }))
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                return
            }))
            present(ac, animated: true)
        } else {
            postAdvert()
        }
    }
    
    @IBAction func signInButtonTapped(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(identifier: "SignInVC") as! SignInViewController
        self.present(vc, animated: true)
    }
    
    
}


//MARK: - Text Delegates

extension PostSpaceViewController: UITextFieldDelegate, UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if descriptionTextView.text == descriptionViewPlaceholder {
            descriptionTextView.text = ""
            descriptionTextView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if descriptionTextView.text == "" {
            descriptionTextView.text = descriptionViewPlaceholder
            descriptionTextView.textColor = .lightGray
        }
        descriptionTextView.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    // - Move screen up
    @objc func keyboardWillShow(_ notifictation: Notification) {
        if priceTextField.isEditing {
            view.frame.origin.y = -getKeyboardHeight(notifictation) + 70
        }
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
        if image.imageName != "placeholder" {
            imagesToUpload.append(image)
        }
        
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


//MARK: - Picker View Delegates and Data Sources

extension PostSpaceViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
        
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1 {
            return spaceTypePickerContent.count
        } else {
            return priceRatePickerContent.count
        }
    }
    
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        if pickerView.tag == 1 {
//            return spaceTypePickerContent[row]
//        } else {
//            return priceRatePickerContent[row]
//        }
//    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
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
        
}
