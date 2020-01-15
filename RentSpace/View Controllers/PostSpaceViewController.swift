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
    var previousCategory = ""
    var priceRate = "Hourly"
    let descriptionViewPlaceholder = "Describe your studio space here..."
    var location = ""
    var advert: [String : Any] = [:]
    var updatingAdvert = false
    var firebaseCloudUIImages = [UIImage]()
    let placeHolderImage = UIImage(named: "imagePlaceholder")
    
    let defaults = UserDefaults.standard
    let UD = UserDefaults.standard
    var advertSnapshot: DataSnapshot?
    var userAdvertsPath = ""
    var advertsPath = ""
    var UID = ""
    var uniqueAdvertID = ""
    var key = ""
    var firebaseImageURLsDict: [String:String] = [:]

    
    //MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        
        if updatingAdvert {
            loadAdvertToUpdate()
        }
        
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
        var email = ""
        var postcode = ""
        if updatingAdvert {
            loadUDImages(for: "UpdateImages")
            email = defaults.string(forKey: "UpdateEmail") ?? ""
            postcode = defaults.string(forKey: "UpdatePostCode") ?? ""
            location = defaults.string(forKey: "UpdateCountry") ?? ""

        } else {
            loadUDImages(for: "Images")
            email = defaults.string(forKey: "Email") ?? ""
            postcode = defaults.string(forKey: "PostCode") ?? ""
            location = defaults.string(forKey: "Country") ?? ""

        }
        locationButton.titleLabel?.text = " \(postcode) / \(email)"
        if email == "" || postcode == "" {
            locationButton.titleLabel?.text = "  Contact & Address"
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
        Auth.auth().removeStateDidChangeListener(handle)
    }
    
  
    
    //MARK: - Private Methods
    
    func loadAdvertToUpdate() {
        defaults.removeObject(forKey: "UpdateImages")
        
        postButton.title = "Update Ad"
        titleTextField.text = advert[Advert.title] as? String
        descriptionTextView.text = advert[Advert.description] as? String
        category = advert[Advert.category] as? String ?? "Art Studio"
        previousCategory = advert[Advert.category] as? String ?? "Art Studio"
        
        for (i, spaceType) in spaceTypePickerContent.enumerated() {
            if spaceType == category {
                spaceTypePicker.selectRow(i, inComponent: 0, animated: true)
            }
        }
        
        priceTextField.text = advert[Advert.price] as? String
        priceRate = advert[Advert.priceRate] as? String ?? "Hourly"
        for (i, rate) in priceRatePickerContent.enumerated() {
            if rate == priceRate {
                priceRatePicker.selectRow(i, inComponent: 0, animated: true)
            }
        }

        defaults.set(advert[Advert.email] as? String, forKey: "UpdateEmail")
        defaults.set(advert[Advert.phone] as? String, forKey: "UpdatePhone")
        defaults.set(advert[Advert.town] as? String, forKey: "UpdateTown")
        defaults.set(advert[Advert.city] as? String, forKey: "UpdateCity")
        defaults.set(advert[Advert.subAdminArea] as? String, forKey: "UpdateSubAdminArea")
        defaults.set(advert[Advert.state] as? String, forKey: "UpdateState")
        defaults.set(advert[Advert.country] as? String, forKey: "UpdateCountry")
        defaults.set(advert[Advert.postCode] as? String, forKey: "UpdatePostCode")
        defaults.set(advert[Advert.viewOnMap] as! Bool, forKey: "UpdateViewOnMap")
        
        // Download images from Firebase Storage
        downloadFirebaseImages {
            for _ in 0...8 {
                self.writeImageFileToDisk(image: self.placeHolderImage!, name: "placeholder", at: 0)
            }
            
            for firebaseUIImage in self.firebaseCloudUIImages {
                let imageName = UUID().uuidString
                // Create array of images on disk
                self.writeImageFileToDisk(image: firebaseUIImage, name: imageName, at: 0)
                self.images.removeLast()
            }
            // Save image file paths to UserDefaults
            let jsonEncoder = JSONEncoder()
            if let savedData = try? jsonEncoder.encode(self.images) {
                self.defaults.set(savedData, forKey: "UpdateImages")
            }
            self.collectionView.reloadData()
        }
    }
    
    // maybe refactor this as its used also in advert deails VC
    func downloadFirebaseImages(completion: @escaping () -> ()) {
        if let imageURLsDict = advert[Advert.photos] as? [String : String] {
            self.firebaseImageURLsDict = imageURLsDict
            for i in 0..<imageURLsDict.count {
                if let imageURL = imageURLsDict["image \(i)"] {
                    Storage.storage().reference(forURL: imageURL).getData(maxSize: INT64_MAX) { (data, error) in
                        guard error == nil else {
                            print("error downloading: \(error?.localizedDescription ?? error.debugDescription)")
                            return
                        }
                        if let data = data {
                            if let image = UIImage(data: data) {
                                self.firebaseCloudUIImages.append(image)
                                if self.firebaseCloudUIImages.count == imageURLsDict.count {
                                    completion()
                                }
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
        images.insert(savingImage, at: position)
    }
    
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
         
         // Space type & Price rate pickers
         spaceTypePicker.dataSource = self
         spaceTypePicker.delegate = self
         priceRatePicker.dataSource = self
         priceRatePicker.delegate = self
         spaceTypePickerContent = ["Art Studio", "Photography Studio", "Music Studio", "Desk Space"]
         priceRatePickerContent = ["Hourly", "Daily", "Weekly", "Monthly", "Annually"]

         priceTextField.attributedPlaceholder = NSAttributedString(string: "Price", attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray])
        
         signInButton.layer.cornerRadius = 5
         uploadView.isHidden = true
     }
    
    func getDocumentsDirectory() -> URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return path[0]
    }
    
    fileprivate func loadUDImages(for key: String) {
        if let imageData = UserDefaults.standard.data(forKey: key) {
            do {
                let jsonDecoder = JSONDecoder()
                images = try jsonDecoder.decode([Image].self, from: imageData)
            } catch {
                print("Data could not be decoded: \(error)")
            }
        }
        collectionView.reloadData()
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
        let data: [String : Any] = [Advert.title: self.titleTextField.text!,
                                    Advert.description: descriptionText as Any,
                                    Advert.category: self.category,
                                    Advert.price: priceTextField.text as Any,
                                    Advert.priceRate: priceRate,
                                    Advert.phone: UD.string(forKey: "\(update)Phone") as Any,
                                    Advert.email: UD.string(forKey: "\(update)Email") as Any,
                                    Advert.address: UD.string(forKey: "\(update)Address") as Any,
                                    Advert.postCode: UD.string(forKey: "\(update)PostCode") as Any,
                                    Advert.city: UD.string(forKey: "\(update)City") as Any,
                                    Advert.subAdminArea: UD.string(forKey: "\(update)SubAdminArea") as Any,
                                    Advert.state: UD.string(forKey: "\(update)State") as Any,
                                    Advert.country: UD.string(forKey: "\(update)Country") as Any,
                                    Advert.town: UD.string(forKey: "\(update)Town") as Any,
                                    Advert.photos: imageURLs as Any,
                                    Advert.viewOnMap: UD.bool(forKey: "\(update)ViewOnMap")]
        
        // Write to Adverts firebase pathes
        
        if updatingAdvert {
            var childUpdates = ["\(advertsPath)-\(key)": data,
                                "\(userAdvertsPath)/\(key)": data] as [String : Any]
            
            // If user has changed categories - add another path to dictionary to delete old advert
            if category != previousCategory {
                childUpdates["adverts/\(Constants.userLocationCountry)/\(previousCategory)/\(UID)-\(key)"] = NSNull()
            }
            
            self.ref.updateChildValues(childUpdates) { (error, databaseRef) in
                if error != nil {
                    print(error?.localizedDescription as Any)
                }
                print("update completion")
                self.images = []
                self.imagesToUpload = []
                let vc = self.storyboard?.instantiateViewController(identifier: "PostConfirmationVC") as! PostConfirmationViewController
                self.present(vc, animated: true)
            }
        } else {
            self.ref.child("\(advertsPath)-\(uniqueAdvertID)").setValue(data) { (error, reference) in
                if error != nil {
                    print(error?.localizedDescription as Any)
                    // TODO: - HANDLE ERROR
                    return
                }
                
                self.ref.child("\(self.userAdvertsPath)/\(self.uniqueAdvertID)").setValue(data) { (userError, ref) in
                    if userError != nil {
                        print(userError as Any)
                    }
                    
                    print("Upload Complete")
                    let domain = Bundle.main.bundleIdentifier!
                    self.UD.removePersistentDomain(forName: domain)
                    self.UD.synchronize()
                    
                    self.titleTextField.text = ""
                    self.priceTextField.text = ""
                    self.locationButton.setTitle("Contact & Address", for: .normal)
                    self.configureUI()
                    self.images = []
                    self.imagesToUpload = []
                    self.collectionView.reloadData()
                    
                    let vc = self.storyboard?.instantiateViewController(identifier: "PostConfirmationVC") as! PostConfirmationViewController
                    self.present(vc, animated: true)
                }
            }
        }
    }
    
    func postAdvert() {
        key = advertSnapshot?.key ?? ""
        uniqueAdvertID = UUID().uuidString
        UID = Settings.currentUser!.uid
        advertsPath = "adverts/\(self.location)/\(self.category)/\(UID)"
        userAdvertsPath = "users/\(UID)/adverts"
        uploadView.isHidden = false
        
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
                        print("Image Deleted: \(deletedImagesCount)")
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
        
        print("images to upload \(imagesToUpload.count)")
        
        for image in imagesToUpload {
            let imageFile = getDocumentsDirectory().appendingPathComponent(image.imageName)
            let UIImageVersion = UIImage(contentsOfFile: imageFile.path)
            
            if let imageData = UIImageVersion?.jpegData(compressionQuality: 0.2) {
                var imagePath = ""
                if updatingAdvert {
                    imagePath = "\(userAdvertsPath)/\(key)"
                } else {
                    imagePath = "\(userAdvertsPath)/\(uniqueAdvertID)"
                }
                
                let metaData = StorageMetadata()
                metaData.contentType = "image/jpeg"
                let advertRef = storageRef.child(imagePath)
                
                advertRef.child("\(imageIndex).jpg").putData(imageData, metadata: metaData) { (metadata, error) in
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
                imageIndex += 1
            }
        }
    }
    
    
    deinit {

        print("deinit called")
    }
    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "ContactDetails" {
            if updatingAdvert {
                let contactVC = segue.destination as! ContactDetailsViewController
                contactVC.inUpdateMode = true
                contactVC.advert = advert
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

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}
