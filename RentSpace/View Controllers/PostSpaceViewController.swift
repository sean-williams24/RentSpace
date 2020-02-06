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
    var imagesSavedToDisk = [Image]()
    var imagesToUpload: [Image] = []
    let itemsPerRow: CGFloat = 5
    let collectionViewInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
//    var ref: DatabaseReference!
//    var storageRef: StorageReference!
    fileprivate var handle: AuthStateDidChangeListenerHandle!
    var category = "Art Studio"
    var previousCategory = ""
    var priceRate = "Hourly"
    let descriptionViewPlaceholder = "Describe your studio space here..."
    var location = ""
    var space: Space!
    var updatingAdvert = false
    let placeHolderImage = UIImage(named: "imagePlaceholder")
    let defaults = UserDefaults.standard
    let UD = UserDefaults.standard
    var userAdvertsPath = ""
    var advertsPath = ""
    var UID = ""
    var uniqueAdvertID = ""
    var firebaseImageURLsDict: [String:String] = [:]
    var imagesDictionary: [String: UIImage] = [:]
    
    
    //MARK: - Life Cycle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if updatingAdvert {
            loadAdvertToUpdate()
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            collectionViewHeightConstraint.constant = 420
        }
        
        dismissKeyboardOnViewTap()
        
//        ref = Database.database().reference()
//        storageRef = Storage.storage().reference()
    }
    

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureUI()
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
        
        
        // Add Photos Button
        if imagesSavedToDisk.isEmpty == false {
            UIView.animate(withDuration: 0.5) {
                self.addPhotosButton.imageView?.alpha = 0.1
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.resignFirstResponder()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
        Auth.auth().removeStateDidChangeListener(handle)

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.navigationController!.isBeingDismissed {
            for image in imagesToUpload {
                if image.imageName != "placeholder" {
                    let imageURLInDocuments = getDocumentsDirectory().appendingPathComponent(image.imageName)
                    deleteFileFromDisk(at: imageURLInDocuments)
                }
            }
        }
    }
    
    
    
    //MARK: - Private Methods
    
    
    fileprivate func loadUserDataFromUserDefaults() {
        var email = ""
        var postcode = ""
        if updatingAdvert {
            loadUDImages(for: "UpdateImages")
            descriptionTextView.text = defaults.string(forKey: "UpdateDescription")
            email = defaults.string(forKey: "UpdateEmail") ?? ""
            postcode = defaults.string(forKey: "UpdatePostCode") ?? ""
            location = defaults.string(forKey: "UpdateCountry") ?? ""
        } else {
            loadUDImages(for: "Images")
            descriptionTextView.text = defaults.string(forKey: "Description") ?? descriptionViewPlaceholder
            email = defaults.string(forKey: "Email") ?? ""
            postcode = defaults.string(forKey: "PostCode") ?? ""
            location = defaults.string(forKey: "Country") ?? ""
        }
 
        locationButton.setTitle(" \(postcode) / \(email)", for: .normal)
        if email == "" || postcode == "" {
            locationButton.setTitle("  Contact & Address", for: .normal)
        }
    }
    
    func loadAdvertToUpdate() {
        defaults.removeObject(forKey: "UpdateImages")
        
        postButton.title = "Update"
        titleTextField.text = space.title
        descriptionTextView.text = space.description
        category = space.category
        previousCategory = space.category
        
        for (i, spaceType) in spaceTypePickerContent.enumerated() {
            if spaceType == category {
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
                self.writeImageFileToDisk(image: self.placeHolderImage!, name: "placeholder", at: 0)
            }
            // Save images to disk to create array of filepaths, save to UD so it can be used to load in AddPhotosVC as well as here.

            for key in self.imagesDictionary.keys.sorted().reversed() {
                guard let image = self.imagesDictionary[key] else { break }
                let imageName = UUID().uuidString
                self.writeImageFileToDisk(image: image, name: imageName, at: 0)
                self.imagesSavedToDisk.removeLast()
            }
            
            // Save image file paths to UserDefaults
            let jsonEncoder = JSONEncoder()
            if let savedData = try? jsonEncoder.encode(self.imagesSavedToDisk) {
                self.defaults.set(savedData, forKey: "UpdateImages")
            }
            self.collectionView.reloadData()
        }
    }
    
    // maybe refactor this as its used also in advert deails VC
    func downloadFirebaseImages(completion: @escaping () -> ()) {
        if let imageURLsDict = space.photos {
            self.firebaseImageURLsDict = imageURLsDict
            
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
    
    func writeImageFileToDisk(image: UIImage, name imageName: String, at position: Int) {
        let filePath = getDocumentsDirectory().appendingPathComponent(imageName)
        
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            try? imageData.write(to: filePath)
        }
        
        let savingImage = Image(imageName: imageName)
        imagesSavedToDisk.insert(savingImage, at: position)
        
    }
    
    
    fileprivate func configureUI() {
        // Title textfield
        addLeftPadding(for: titleTextField, placeholderText: "Title", placeholderColour: .lightGray)
        
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
        
        // Space type & Price rate pickers
        spaceTypePicker.dataSource = self
        spaceTypePicker.delegate = self
        priceRatePicker.dataSource = self
        priceRatePicker.delegate = self
        spaceTypePickerContent = ["Art Studio", "Photography Studio", "Music Studio", "Desk Space"]
        priceRatePickerContent = ["Hourly", "Daily", "Weekly", "Monthly", "Annually"]
        priceTextField.attributedPlaceholder = NSAttributedString(string: "Price", attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray])
        
        signInButton.layer.cornerRadius = Settings.cornerRadius
        uploadView.isHidden = true
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
        self.UD.removeObject(forKey: "Phone")
        self.UD.removeObject(forKey: "Email")
        self.UD.removeObject(forKey: "Address")
        self.UD.removeObject(forKey: "PostCode")
        self.UD.removeObject(forKey: "City")
        self.UD.removeObject(forKey: "SubAdminArea")
        self.UD.removeObject(forKey: "State")
        self.UD.removeObject(forKey: "Country")
        self.UD.removeObject(forKey: "Town")
        self.UD.removeObject(forKey: "Images")
        self.UD.set(self.descriptionViewPlaceholder, forKey: "Description")
        self.UD.set(true, forKey: "ViewOnMap")
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
        var descriptionText = descriptionTextView.text
        var update = ""
        
        if descriptionText == descriptionViewPlaceholder {
            descriptionText = ""
        }
        
        if updatingAdvert {
            update = "Update"
        }
        
        // Package advert into data dictionary
        let data = Space(title: self.titleTextField.text ?? "",
                              description: descriptionText ?? "",
                              category: self.category,
                              price: priceTextField.text ?? "",
                              priceRate: priceRate,
                              email: UD.string(forKey: "\(update)Email") ?? "",
                              phone: UD.string(forKey: "\(update)Phone") ?? "",
                              photos: imageURLs,
                              town: UD.string(forKey: "\(update)Town") ?? "",
                              city: UD.string(forKey: "\(update)City") ?? "",
                              subAdminArea: UD.string(forKey: "\(update)SubAdminArea") ?? "",
                              postcode: UD.string(forKey: "\(update)PostCode") ?? "",
                              state: UD.string(forKey: "\(update)State") ?? "",
                              country: UD.string(forKey: "\(update)Country") ?? "",
                              viewOnMap: UD.bool(forKey: "\(update)ViewOnMap"),
                              postedByUser: Settings.currentUser?.uid ?? "",
                              userDisplayName: Settings.currentUser?.displayName ?? "",
                              timestamp: Date().timeIntervalSince1970 as Double)

        
        // Write to Adverts firebase pathes
        if updatingAdvert {
            var childUpdates = ["\(advertsPath)-\(space.key)": data.toAnyObject(),
                                "\(userAdvertsPath)/\(space.key)": data.toAnyObject()]
            
            // If user has changed categories - add another path to dictionary to delete old advert
            if category != previousCategory {
                childUpdates["adverts/\(Constants.userLocationCountry)/\(previousCategory)/\(UID)-\(space.key)"] = NSNull()
            }
            
            Settings.ref.updateChildValues(childUpdates) { [weak self] (error, databaseRef) in
                if error != nil {
                    print(error?.localizedDescription as Any)
                }
                print("update completion")
                self?.imagesSavedToDisk = []
                self?.imagesToUpload = []
                
                let vc = self?.storyboard?.instantiateViewController(identifier: "PostConfirmationVC") as! PostConfirmationViewController
                vc.modalPresentationStyle = .fullScreen
                vc.updatingAdvert = true
                self?.present(vc, animated: true)
            }
        } else {
            Settings.ref.child("\(advertsPath)-\(uniqueAdvertID)").setValue(data.toAnyObject()) { [weak self] (error, reference) in
                if error != nil {
                    print(error?.localizedDescription as Any)
                    // TODO: - HANDLE ERROR
                    return
                }
                
                Settings.ref.child("\(self?.userAdvertsPath ?? "")/\(self?.uniqueAdvertID ?? "")").setValue(data.toAnyObject()) { (userError, ref) in
                    if userError != nil {
                        print(userError as Any)
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
                deleteImagesFromFirebaseCloudStorage {
                    self.uploadAdvertToFirebase()
                }
            } else {
                uploadAdvertToFirebase()
            }
        } else {
            // If there are images to upload, if we are updating the advert, there are existing images and images have been updated -
            // delete old photos first then upload again to same path in cloud storage.
            if updatingAdvert && firebaseImageURLsDict.count != 0 && imagesUpdated == true {
                print("Images have been updated")
                
                deleteImagesFromFirebaseCloudStorage {
                    self.uploadImagesToFirebaseCloudStorage { (imageURLs) in
                        self.uploadAdvertToFirebase(imageURLs)
                    }
                }
                // If there are images to upload, if we are updating the advert, there are existing images but images have not been updated -
                // overwrite photos to same path in cloud storage.
            } else if updatingAdvert && firebaseImageURLsDict.count != 0 && imagesUpdated == false {
                print("Images have not been updated")
                
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
    
    func deleteImagesFromFirebaseCloudStorage(completion: @escaping() -> ()) {
        let storage = Storage.storage()
        var deletedImagesCount = 0
        for (_, imageURL) in firebaseImageURLsDict {
            let storRef = storage.reference(forURL: imageURL)
            
            storRef.delete { (error) in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    deletedImagesCount += 1
                    
                    if deletedImagesCount == self.firebaseImageURLsDict.count {
                        // Call completion and uploadImagestofirebasestorage
                        print("Uploading to Firebase Storage and Realtime Database")
                        completion()
                    }
                }
            }
        }
    }
    
    
    
    func uploadImagesToFirebaseCloudStorage(completion: @escaping ([String : String]) -> ()) {
        var imageURLs: [String : String] = [:]
        var uploadedImagesCount = 0
        var imageIndex = 1
        let storageRef = Settings.storageRef
        
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
                    print("uploadoaded images count: \(uploadedImagesCount)")
                    
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
        if descriptionTextView.text == descriptionViewPlaceholder {
            descriptionTextView.text = ""
            descriptionTextView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if descriptionTextView.text == "" {
            descriptionTextView.text = descriptionViewPlaceholder
            descriptionTextView.textColor = .lightGray
            UD.set(descriptionTextView.text, forKey: "Description")
        } else {
            UD.set(descriptionTextView.text, forKey: "Description")
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
        label.textColor = .black
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
