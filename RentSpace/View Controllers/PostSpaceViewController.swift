//
//  ViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 26/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import FirebaseAuth
import Firebase
import NVActivityIndicatorView
import UIKit
import Contacts

class PostSpaceViewController: UIViewController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
    // MARK: - Outlets
    
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
    @IBOutlet var uploadView: UIView!
    @IBOutlet var signedOutView: UIView!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet var imagesActivityView: NVActivityIndicatorView!
    @IBOutlet weak var stackView: UIStackView!
    
    
    // MARK: - Properties
    
    var spaceTypePickerContent = [String]()
    var priceRatePickerContent = [String]()
    var imagesSavedToDisk = [Image]()
    var imagesToUpload: [Image] = []
    var tempDiskImagesArrayToDelete: [Image] = []
    let itemsPerRow: CGFloat = 5
    let collectionViewInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    fileprivate var handle: AuthStateDidChangeListenerHandle!
    var category = "Art Studio"
    var originalCategory = ""
    var priceRate = "Hourly"
    let descriptionViewPlaceholder = "Describe your studio space here..."
    var location = ""
    var space: Space!
    var updatingAdvert = false
    let placeHolderImage = UIImage(named: "imagePlaceholder")
    let defaults = UserDefaults.standard
    var userAdvertsPath = ""
    var advertsPath = ""
    var UID = ""
    var uniqueAdvertID = ""
    var firebaseImageURLsDict: [String:String] = [:]
    var imagesDictionary: [String: UIImage] = [:]
    let hideKeyboardButtonSpacePicker = UIButton()
    let hideKeyboardButtonPricePicker = UIButton()

    
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        
        if updatingAdvert { loadAdvertToUpdate() }
        
        let cellHeight = view.bounds.width / 5
        collectionViewHeightConstraint.constant = (cellHeight * 2) + 6
        
        UIView.animate(withDuration: 0.5) {
            self.addPhotosButton.imageView?.alpha = 0.1
        }

        dismissKeyboardOnViewTap()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserDataFromUserDefaults()
        subscribeToKeyboardNotificationsPostVC()
        imagesToUpload = []
        
        handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            if user == nil {
                self.signedOutView.isHidden = false
                self.postButton.isEnabled = false
            } else {
                self.signedOutView.isHidden = true
                self.postButton.isEnabled = true
                Settings.currentUser = user
            }
        })
        
        UIView.animate(withDuration: 0.5) {
            self.addPhotosButton.imageView?.alpha = 0.1
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.resignFirstResponder()
        let height = priceRatePicker.frame.height

        hideKeyboardButtonSpacePicker.frame = CGRect(x: 0, y: descriptionTextView.frame.maxY + 3, width: view.frame.width, height: height)
        hideKeyboardButtonSpacePicker.addTarget(self, action: #selector(tapAndHideKeyboard), for: .touchUpInside)
        hideKeyboardButtonSpacePicker.isUserInteractionEnabled = false
        view.addSubview(hideKeyboardButtonSpacePicker)
        
        hideKeyboardButtonPricePicker.frame = CGRect(x: view.frame.width / 2, y: descriptionTextView.frame.maxY + height + 6, width: view.frame.width / 2, height: height)
        hideKeyboardButtonPricePicker.addTarget(self, action: #selector(tapAndHideKeyboard), for: .touchUpInside)
        hideKeyboardButtonPricePicker.isUserInteractionEnabled = false
        view.addSubview(hideKeyboardButtonPricePicker)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
        Auth.auth().removeStateDidChangeListener(handle)
        
        if updatingAdvert {
            defaults.set(descriptionTextView.text, forKey: "UpdateDescription")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.navigationController!.isBeingDismissed { deleteImagesInDocumentsDirectory() }
    }
    
    
    
    //MARK: - Private Methods

    
    fileprivate func deleteImagesInDocumentsDirectory() {
        
        for image in imagesToUpload {
            if image.imageName != "placeholder" {
                let imageURLInDocuments = getDocumentsDirectory().appendingPathComponent(image.imageName)
                deleteFileFromDisk(at: imageURLInDocuments)
            }
        }
        
        for image in imagesSavedToDisk {
            if image.imageName != "placeholder" {
                let imageURLinDocuments = getDocumentsDirectory().appendingPathComponent(image.imageName)
                deleteFileFromDisk(at: imageURLinDocuments)
            }
        }
        
        for image in tempDiskImagesArrayToDelete {
            if image.imageName != "placeholder" {
                let imageURLinDocuments = getDocumentsDirectory().appendingPathComponent(image.imageName)
                deleteFileFromDisk(at: imageURLinDocuments)
            }
        }
    }
    
    
    fileprivate func loadUserDataFromUserDefaults() {
        var email = ""
        var city = ""
        
        let description = defaults.string(forKey: "UpdateDescription")
        if updatingAdvert {
            loadUDImages(for: "UpdateImages")
            descriptionTextView.text = description == "" ? descriptionViewPlaceholder : description
            email = defaults.string(forKey: "UpdateEmail") ?? ""
            city = defaults.string(forKey: "UpdateCity") ?? ""
            location = defaults.string(forKey: "UpdateCountry") ?? ""
        } else {
            loadUDImages(for: "Images")
            descriptionTextView.text = defaults.string(forKey: "Description") ?? descriptionViewPlaceholder
            descriptionTextView.textColor = descriptionTextView.text == descriptionViewPlaceholder ? .lightGray : .white

            email = defaults.string(forKey: "Email") ?? ""
            city = defaults.string(forKey: "City") ?? ""
            location = defaults.string(forKey: "Country") ?? ""
        }
        
        locationButton.setTitle(" \(city) / \(email)", for: .normal)
        if email == "" || city == "" {
            locationButton.setTitle("  Contact & Address", for: .normal)
        }
    }
    
    func loadAdvertToUpdate() {
        
        // Remove any existing temp images from documents
        if let imageFilePaths = UserDefaults.standard.data(forKey: "UpdateImages") {
            do {
                let jsonDecoder = JSONDecoder()
                let oldImages = try jsonDecoder.decode([Image].self, from: imageFilePaths)
                for image in oldImages {
                  let imageURL = getDocumentsDirectory().appendingPathComponent(image.imageName)
                    if image.imageName != "placeholder" {
                        deleteFileFromDisk(at: imageURL)
                    }
                }
            } catch {
                print("Data could not be decoded: \(error)")
                showAlert(title: "Oops", message: "There was a problem loading your saved images, please try reloading the page.")
            }
        }
        
        defaults.removeObject(forKey: "UpdateImages")
        postButton.title = "Update"
        titleTextField.text = space.title
        descriptionTextView.text = space.description == "" ? descriptionViewPlaceholder : space.description
        category = space.category
        originalCategory = space.category
        
        for (i, spaceType) in spaceTypePickerContent.enumerated() {
            if spaceType == space.category {
                spaceTypePicker.selectRow(i, inComponent: 0, animated: true)
            }
        }
        
        priceTextField.text = space.price
        priceRate = space.priceRate
        for (i, rate) in priceRatePickerContent.enumerated() {
            if rate == priceRate {
                priceRatePicker.selectRow(i, inComponent: 0, animated: true)
            }
        }
        
        defaults.set(space.email, forKey: "UpdateEmail")
        defaults.set(space.phone, forKey: "UpdatePhone")
        defaults.set(space.town, forKey: "UpdateTown")
        defaults.set(space.city, forKey: "UpdateCity")
        defaults.set(space.subAdminArea, forKey: "UpdateSubAdminArea")
        defaults.set(space.state, forKey: "UpdateState")
        defaults.set(space.country, forKey: "UpdateCountry")
        defaults.set(space.postcode, forKey: "UpdatePostCode")
        defaults.set(space.viewOnMap, forKey: "UpdateViewOnMap")
        defaults.set(space.description, forKey: "UpdateDescription")
        
        // Download images from Firebase Storage
        downloadFirebaseImages {
            for _ in 0...8 {
                self.writeImageFileToDisk(image: self.placeHolderImage!, name: "placeholder", at: 0, in: &self.imagesSavedToDisk)
            }
            // Save images to disk to create array of filepaths, save to UD so it can be used to load in AddPhotosVC as well as here.
            
            for key in self.imagesDictionary.keys.sorted().reversed() {
                guard let image = self.imagesDictionary[key] else { break }
                let imageName = UUID().uuidString
                self.writeImageFileToDisk(image: image, name: imageName, at: 0, in: &self.imagesSavedToDisk)
                self.imagesSavedToDisk.removeLast()
            }
            
            self.tempDiskImagesArrayToDelete = self.imagesSavedToDisk
            
            // Save image file paths to UserDefaults
            let jsonEncoder = JSONEncoder()
            if let savedData = try? jsonEncoder.encode(self.imagesSavedToDisk) {
                self.defaults.set(savedData, forKey: "UpdateImages")
            }
            
            self.imagesActivityView.stopAnimating()
            self.collectionView.reloadData()
            UIView.animate(withDuration: 0.5) {
                self.addPhotosButton.imageView?.alpha = 0.1
            }
        }
    }
    
    
    func downloadFirebaseImages(completion: @escaping () -> ()) {
        if let imageURLsDict = space.photos {
            self.firebaseImageURLsDict = imageURLsDict
            imagesActivityView.startAnimating()
            
            for key in imageURLsDict.keys.sorted()  {
                guard let value = imageURLsDict[key] else { break }
                
                Storage.storage().reference(forURL: value).getData(maxSize: INT64_MAX) { [weak self] (data, error) in
                    guard error == nil else {
                        print("error downloading: \(error?.localizedDescription ?? error.debugDescription)")
                        return
                    }
                    
                    if let data = data {
                        if let image = UIImage(data: data) {
                            self?.imagesDictionary[key] = image
                            if self?.imagesDictionary.count == imageURLsDict.count {
                                completion()
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    fileprivate func configureUI() {
        // Title textfield
        addLeftPadding(for: titleTextField, placeholderText: "Title", placeholderColour: .lightGray)
        titleTextField.tintColor = .black
        
        // Description textView
        descriptionTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 4, right: 4)
        descriptionTextView.text = descriptionViewPlaceholder
        descriptionTextView.delegate = self
        descriptionTextView.tintColor = .black

        descriptionTextView.textColor = descriptionTextView.text == descriptionViewPlaceholder ? .lightGray : .white
        
        // Location Button
        addDisclosureAccessoryView(for: locationButton)
        
        // Space type & Price rate pickers
        spaceTypePicker.dataSource = self
        spaceTypePicker.delegate = self
        priceRatePicker.dataSource = self
        priceRatePicker.delegate = self
        spaceTypePickerContent = ["Art Studio", "Photography Studio", "Music Studio", "Desk Space"]
        priceRatePickerContent = ["Hourly", "Daily", "Weekly", "Monthly", "Annually"]
        priceTextField.attributedPlaceholder = NSAttributedString(string: "Price", attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray])
        priceTextField.tintColor = .black
        
        signInButton.layer.cornerRadius = Settings.cornerRadius
        uploadView.isHidden = true
        
        let insets = UIEdgeInsets(top: 45, left: 0, bottom: 55, right: 0)
        addPhotosButton.imageEdgeInsets = insets
        addPhotosButton.imageView?.contentMode = .scaleAspectFit
        

    }
    
    @objc func tapAndHideKeyboard(sender: UIButton!) {
        view.endEditing(true)
        hideKeyboardButtonSpacePicker.isUserInteractionEnabled = false
        hideKeyboardButtonPricePicker.isUserInteractionEnabled = false
    }
    
    
    fileprivate func loadUDImages(for key: String) {
        if let imageData = UserDefaults.standard.data(forKey: key) {
            do {
                let jsonDecoder = JSONDecoder()
                imagesSavedToDisk = try jsonDecoder.decode([Image].self, from: imageData)
            } catch {
                print("Data could not be decoded: \(error)")
            }
        }
        collectionView.reloadData()
    }
    
    
    fileprivate func resetUIandUserDefaults() {
        self.defaults.removeObject(forKey: "Phone")
        self.defaults.removeObject(forKey: "Email")
        self.defaults.removeObject(forKey: "Address")
        self.defaults.removeObject(forKey: "PostCode")
        self.defaults.removeObject(forKey: "City")
        self.defaults.removeObject(forKey: "SubAdminArea")
        self.defaults.removeObject(forKey: "State")
        self.defaults.removeObject(forKey: "Country")
        self.defaults.removeObject(forKey: "Town")
        self.defaults.removeObject(forKey: "Images")
        self.defaults.set(self.descriptionViewPlaceholder, forKey: "Description")
        self.defaults.set(true, forKey: "ViewOnMap")
        self.titleTextField.text = ""
        self.priceTextField.text = ""
        self.locationButton.setTitle("Contact & Address", for: .normal)
        self.configureUI()
        self.imagesSavedToDisk = []
        self.imagesToUpload = []
        self.collectionView.reloadData()
        self.postButton.isEnabled = true
    }
    
    
    
    fileprivate func uploadAdvertToFirebase(_ imageURLs: [String : String]? = nil) {
        let ref = FirebaseClient.databaseRef
        let descriptionText = descriptionTextView.text == descriptionViewPlaceholder ? "" : descriptionTextView.text
        let update = updatingAdvert ? "Update" : ""
        
        // Package advert into data dictionary
        let data = Space(title: self.titleTextField.text ?? "",
                         description: descriptionText ?? "",
                         category: self.category,
                         price: priceTextField.text ?? "",
                         priceRate: priceRate,
                         email: defaults.string(forKey: "\(update)Email") ?? "",
                         phone: defaults.string(forKey: "\(update)Phone") ?? "",
                         photos: imageURLs,
                         town: defaults.string(forKey: "\(update)Town") ?? "",
                         city: defaults.string(forKey: "\(update)City") ?? "",
                         subAdminArea: defaults.string(forKey: "\(update)SubAdminArea") ?? "",
                         postcode: defaults.string(forKey: "\(update)PostCode") ?? "",
                         state: defaults.string(forKey: "\(update)State") ?? "",
                         country: defaults.string(forKey: "\(update)Country") ?? "",
                         viewOnMap: defaults.bool(forKey: "\(update)ViewOnMap"),
                         postedByUser: Settings.currentUser?.uid ?? "",
                         userDisplayName: Settings.currentUser?.displayName ?? "",
                         timestamp: Date().timeIntervalSince1970 as Double)
        
        
        // Write to Adverts firebase pathes
        if updatingAdvert {
            var childUpdates = ["\(advertsPath)-\(space.key)": data.toAnyObject(),
                                "\(userAdvertsPath)/\(space.key)": data.toAnyObject()]
            
            // If user has changed categories - add another path to dictionary to delete old advert
            if category != originalCategory {
                childUpdates["adverts/\(Location.userLocationCountry)/\(originalCategory)/\(UID)-\(space.key)"] = NSNull()
            }
            
            ref.updateChildValues(childUpdates) { [weak self] (error, databaseRef) in
                if error != nil {
                    print(error?.localizedDescription as Any)
                }
                print("update completion")
                
                self?.deleteImagesInDocumentsDirectory()
                self?.imagesSavedToDisk = []
                self?.imagesToUpload = []
                
                let vc = self?.storyboard?.instantiateViewController(identifier: "PostConfirmationVC") as! PostConfirmationViewController
                vc.modalPresentationStyle = .fullScreen
                vc.updatingAdvert = true
                self?.present(vc, animated: true)
            }
        } else {
            ref.child("\(advertsPath)-\(uniqueAdvertID)").setValue(data.toAnyObject()) { [weak self] (error, reference) in
                if error != nil {
                    print(error?.localizedDescription as Any)
                    self?.showAlert(title: "Oh No!", message: "There was a problem uploading your advert; we apologise for the inconvenience. Please try posting your space again.")
                    return
                }
                
                ref.child("\(self?.userAdvertsPath ?? "")/\(self?.uniqueAdvertID ?? "")").setValue(data.toAnyObject()) { (userError, ref) in
                    if userError != nil {
                        print(userError as Any)
                        self?.showAlert(title: "Oh No!", message: "There was a problem uploading your advert; we apologise for the inconvenience. Please try posting your space again.")
                        return
                    }
                    
                    print("Upload Complete")
                    self?.resetUIandUserDefaults()
                    
                    let vc = self?.storyboard?.instantiateViewController(identifier: "PostConfirmationVC") as! PostConfirmationViewController
                    self?.present(vc, animated: true)
                }
            }
        }
    }
    
    func postAdvert() {
        uniqueAdvertID = UUID().uuidString
        UID = Settings.currentUser!.uid
        advertsPath = "adverts/\(self.location)/\(self.category)/\(UID)"
        userAdvertsPath = "users/\(UID)/adverts"
        uploadView.isHidden = false
        postButton.isEnabled = false
        self.view.endEditing(true)
        
        let imagesUpdated = defaults.bool(forKey: "ImagesUpdated")
        
        // If there are no images to upload - upload directly to Realtime database
        if imagesToUpload.isEmpty {
            // If there are existing images - delete them first
            if firebaseImageURLsDict.count != 0 {
                FirebaseClient.deleteImagesFromFirebaseCloudStorage(imageURLsDict: firebaseImageURLsDict) {
                    self.uploadAdvertToFirebase()
                }
            } else {
                uploadAdvertToFirebase()
            }
        } else {
            // If there are images to upload, if we are updating the advert, there are existing images and images have been updated -
            // delete old photos first then upload again to same path in cloud storage.
            if updatingAdvert && firebaseImageURLsDict.count != 0 && imagesUpdated == true {
                FirebaseClient.deleteImagesFromFirebaseCloudStorage(imageURLsDict: firebaseImageURLsDict) {
                    self.uploadImagesToFirebaseCloudStorage { (imageURLs) in
                        self.uploadAdvertToFirebase(imageURLs)
                    }
                }
                // If there are images to upload, if we are updating the advert, there are existing images but images have not been updated -
                // overwrite photos to same path in cloud storage.
            } else if updatingAdvert && firebaseImageURLsDict.count != 0 && imagesUpdated == false {
                self.uploadImagesToFirebaseCloudStorage { (imageURLs) in
                    self.uploadAdvertToFirebase(imageURLs)
                }
            } else {
                // If posting new advert and there are images to upload
                uploadImagesToFirebaseCloudStorage { (imageURLs) in
                    self.uploadAdvertToFirebase(imageURLs)
                }
            }
        }
    }
    
    
    func uploadImagesToFirebaseCloudStorage(completion: @escaping ([String : String]) -> ()) {
        var imageURLs: [String : String] = [:]
        var uploadedImagesCount = 0
        var imageIndex = 1
        let storageRef = FirebaseClient.storageRef
        
        for image in imagesToUpload {
            let imageURLInDocuments = getDocumentsDirectory().appendingPathComponent(image.imageName)
            let UIImageVersion = UIImage(contentsOfFile: imageURLInDocuments.path)
            
            if let imageData = UIImageVersion?.jpegData(compressionQuality: 0.4) {
                var imagePath = ""
                if updatingAdvert {
                    imagePath = "\(userAdvertsPath)/\(space.key)"
                } else {
                    imagePath = "\(userAdvertsPath)/\(uniqueAdvertID)"
                }
                
                let metaData = StorageMetadata()
                metaData.contentType = "image/jpeg"
                let advertRef = storageRef.child(imagePath)
                
                advertRef.child("\(imageIndex).jpg").putData(imageData, metadata: metaData) { [weak self] (metadata, error) in
                    if let error = error {
                        print("Error uploading: \(error)")
                        return
                    }
                    
                    // Get URL for photo and add to dictionary
                    let url = storageRef.child((metadata?.path)!).description
                    let imageStoragePath = storageRef.child((metadata?.name)!).description
                    let imageNumber = imageStoragePath.deletingPrefix(storageRef.description)
                    
                    imageURLs["image \(imageNumber.first!)"] = url
                    uploadedImagesCount += 1
                    
                    self?.deleteFileFromDisk(at: imageURLInDocuments)
                    
                    // Call completion handler once all images are uploaded, passing in imageURLs
                    if uploadedImagesCount == self?.imagesToUpload.count {
                        completion(imageURLs)
                    }
                }
                imageIndex += 1
            }
        }
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ContactDetails" {
            if updatingAdvert {
                let contactVC = segue.destination as! ContactDetailsViewController
                contactVC.inUpdateMode = true
            }
        } else if segue.identifier == "AddPhotos" {
            if updatingAdvert {
                let addPhotosVC = segue.destination as! AddPhotosViewController
                addPhotosVC.inUpdatingMode = true
            }
        }
        self.view.endEditing(true)
    }
    
    
    //MARK: - Action Methods
    
    @IBAction func postButtonTapped(_ sender: Any) {
        if titleTextField.text == "" {
            titleTextField.attributedPlaceholder = NSAttributedString(string: "Title", attributes: [NSAttributedString.Key.foregroundColor: Settings.orangeTint])
            if priceTextField.text == "" {
                priceTextField.attributedPlaceholder = NSAttributedString(string: "Price", attributes: [NSAttributedString.Key.foregroundColor: Settings.orangeTint])
            }
            return
        }
        
        guard priceTextField.text != "" else {
            showAlert(title: "Please enter a price...", message: nil)
            priceTextField.attributedPlaceholder = NSAttributedString(string: "Price", attributes: [NSAttributedString.Key.foregroundColor: Settings.orangeTint])
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
        if view.frame.origin.y != 0 {
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                self.view.frame.origin.y = 0
            })
        }
        
        if descriptionTextView.text == descriptionViewPlaceholder {
            descriptionTextView.text = ""
            descriptionTextView.textColor = .white
        }
    }
    
    
    func textViewDidEndEditing(_ textView: UITextView) {
        let update = updatingAdvert ? "Update" : ""

        if isTextViewEmpty(for: descriptionTextView) {
            // if text editing ends and there is no text, set to placeholder
            
            descriptionTextView.text = descriptionViewPlaceholder
            descriptionTextView.textColor = .lightGray
            defaults.set(descriptionTextView.text, forKey: "\(update)Description")
        } else {
            defaults.set(descriptionTextView.text, forKey: "\(update)Description")
        }
        
        descriptionTextView.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    // - Move screen up
    @objc func keyboardWillShowOnPostVC(_ notifictation: Notification) {
        if priceTextField.isEditing {
            view.frame.origin.y = -getKeyboardHeight(notifictation) + 70
        }
        
        hideKeyboardButtonSpacePicker.isUserInteractionEnabled = true
        hideKeyboardButtonPricePicker.isUserInteractionEnabled = true
    }
}


// MARK: - Collection view delegates 


extension PostSpaceViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imagesSavedToDisk.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PreviewPhotoCollectionViewCell
        let image = imagesSavedToDisk[indexPath.item]
        
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
    
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.font = UIFont(name: "HelveticaNeue-Light", size: 16)
        label.textAlignment = .center
        label.textColor = Settings.orangeTint
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

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}
