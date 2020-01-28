//
//  AddPhotosViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 27/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit
import CoreData
import YPImagePicker

class AddPhotosViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    
    let placeHolderImage = UIImage(named: "imagePlaceholder")
    private let itemsPerRow: CGFloat = 3
    private let sectionInsets = UIEdgeInsets(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0)
    var images = [Image]()
    var selectedImages: [Image] = []
    var selectedImagesIndexPathes: [IndexPath] = []
    var trashButton = UIBarButtonItem()
    var cameraButton = UIBarButtonItem()
    
    var deleting: Bool = false {
        didSet {
            if deleting {
                navigationItem.setRightBarButton(trashButton, animated: true)
            } else {
                navigationItem.setRightBarButton(cameraButton, animated: true)
            }
        }
    }
    var inUpdatingMode = false
    var pickedImages = [UIImage]()
    
    
    // MARK: - Life Cycle

    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.allowsMultipleSelection = true
        collectionView.dragInteractionEnabled = true
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        
        trashButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(addOrDeletePhotosTapped(_:)))
        cameraButton = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(addOrDeletePhotosTapped(_:)))
        trashButton.tintColor = UIColor(red:0.92, green:0.49, blue:0.24, alpha:1.0)
        cameraButton.tintColor = UIColor(red:0.92, green:0.49, blue:0.24, alpha:1.0)
        navigationItem.setRightBarButton(cameraButton, animated: true)
        
        if inUpdatingMode {
            loadImagesFromUserDefaults(forKey: "UpdateImages")
        } else {
            loadImagesFromUserDefaults(forKey: "Images")
        }
        
        
        // If there are no saved images, load in 9 placeholders
        if images.isEmpty {
            for _ in 0...8 {
                writeImageFileToDisk(image: placeHolderImage!, name: "placeholder", at: 0)
            }
        }
        
        if !photoAlbumIsFull() {
            cameraButton.isEnabled = true
        } else {
            cameraButton.isEnabled = false
        }
    }
    
    
    //MARK: - Private methods
    
    fileprivate func loadImagesFromUserDefaults(forKey UDimages: String) {
        // Load saved images into images array
        if let imageFilePaths = UserDefaults.standard.data(forKey: UDimages) {
            do {
                let jsonDecoder = JSONDecoder()
                images = try jsonDecoder.decode([Image].self, from: imageFilePaths)
            } catch {
                print("Data could not be decoded: \(error)")
            }
        }
    }
    
//    func getDocumentsDirectory() -> URL {
//        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//        return path[0]
//    }
    
    //Encode photos array to json data and save to user defaults
    func save() {
        let jsonEncoder = JSONEncoder()
        
        if let savedData = try? jsonEncoder.encode(images) {
            if inUpdatingMode {
                UserDefaults.standard.set(savedData, forKey: "UpdateImages")
                print("Change made to images")
                UserDefaults.standard.set(true, forKey: "ImagesUpdated")
            } else {
                UserDefaults.standard.set(savedData, forKey: "Images")
            }
        }
    }
    
    // refactor into extension
    func writeImageFileToDisk(image: UIImage, name imageName: String, at position: Int) {
        let filePath = getDocumentsDirectory().appendingPathComponent(imageName)
        
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            try? imageData.write(to: filePath)
        }
        
        let savingImage = Image(imageName: imageName)
        images.insert(savingImage, at: position)
    }
    
    fileprivate func photoAlbumIsFull() -> Bool {
        var imageNames: [String] = []
        for image in images {
            imageNames.append(image.imageName)
        }
        
        if !imageNames.contains("placeholder") {
            return true
        }
        return false
    }
    
    @objc func addOrDeletePhotosTapped(_ sender: Any) {
        if deleting {
            for indexPath in selectedImagesIndexPathes.reversed() {
                images.remove(at: indexPath.item)
                writeImageFileToDisk(image: placeHolderImage!, name: "placeholder", at: images.count)
                
                //TODO - delete photo from disk
                
            }
            collectionView.reloadData()
            save()
            deleting = false
            selectedImagesIndexPathes.removeAll()
            if !photoAlbumIsFull() {
                navigationItem.rightBarButtonItem?.isEnabled = true
            }
        } else {
            addPhotos()
        }
    }
    
    
    //MARK: - Image Picker Delegates
    
    func addPhotos() {
        var config = YPImagePickerConfiguration()
        let attributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18, weight: .light) ]
        UINavigationBar.appearance().titleTextAttributes = attributes // Title fonts
        UIBarButtonItem.appearance().setTitleTextAttributes(attributes, for: .normal) // Bar Button fonts
    
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : Settings.orangeTint ] // Title color
        UINavigationBar.appearance().tintColor = .darkGray // Left. bar buttons
        
        config.colors.tintColor = Settings.orangeTint // Right bar buttons (actions)
        config.icons.multipleSelectionOnIcon.withTintColor(Settings.orangeTint)
        config.colors.multipleItemsSelectedCircleColor = Settings.orangeTint
       // config.showsCrop = .rectangle(ratio: 1.0)
        config.icons.capturePhotoImage = UIImage(named: "Shutter-Black")!
        config.hidesStatusBar = false
        config.preferredStatusBarStyle = .lightContent
        config.startOnScreen = .library
        config.shouldSaveNewPicturesToAlbum = false
        if UIImagePickerController.isSourceTypeAvailable(.camera) == false {
            config.screens = [.library]
        }
        
        var maxImages = 0
        for image in images {
            if image.imageName == "placeholder" {
                maxImages += 1
            }
        }
        config.wordings.warningMaxItemsLimit = "No more remaining spaces"
        
//        config.wordings.warningMaxItemsLimit = NSAttributedString(string: "NO MORE", attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])
        config.library.maxNumberOfItems = maxImages
        
        let picker = YPImagePicker(configuration: config)
        picker.didFinishPicking { [unowned picker] items, cancelled in
            for item in items {
                switch item {
                case .photo(let photo):
                    let imageName = UUID().uuidString
                    self.writeImageFileToDisk(image: photo.image, name: imageName, at: 0)
                    self.images.removeLast()
                    self.save()
                    
                case .video:
                    print("Video")
                    
                }
            }
            self.collectionView.reloadData()
            picker.dismiss(animated: true, completion: nil)
            if self.photoAlbumIsFull() {
                self.navigationItem.rightBarButtonItem?.isEnabled = false
            }
        }

        
        present(picker, animated: true)
    }
    
    
    
    
    //MARK: - Collection View delegates and data source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Photo cell", for: indexPath) as! PhotoCollectionViewCell
        let image = images[indexPath.item]
        
        let savedImageFile = getDocumentsDirectory().appendingPathComponent(image.imageName)
        cell.cellImageView.image = UIImage(contentsOfFile: savedImageFile.path)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard images[indexPath.item].imageName != "placeholder" else { return false }
        if let selectedItems = collectionView.indexPathsForSelectedItems {
            if selectedItems.contains(indexPath) {
                collectionView.deselectItem(at: indexPath, animated: true)
                return false
            }
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        deleting = true
        selectedImagesIndexPathes.append(indexPath)
        print(selectedImagesIndexPathes)
        print("Deleting: \(deleting)")
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        selectedImagesIndexPathes.removeAll(where: {$0 == indexPath})
        print(selectedImagesIndexPathes)
        if selectedImagesIndexPathes.isEmpty {
            deleting = false
        }
    }
}


// MARK: - Collection View Flow Layout Delegate

extension AddPhotosViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}


// MARK: - Collection View Drag & Drop Delegates


extension AddPhotosViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let image = images[indexPath.item]
        
        if image.imageName == "placeholder" {
            return []
        } else {
            let savedImageFile = getDocumentsDirectory().appendingPathComponent(image.imageName)
            
            let item = NSItemProvider(object: UIImage(contentsOfFile: savedImageFile.path)!)
            let dragItem = UIDragItem(itemProvider: item)
            return[dragItem]
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }
        
        coordinator.items.forEach { dropItem in
            guard let sourceIndexPath = dropItem.sourceIndexPath else { return }
            
            let image = images[sourceIndexPath.item]
            let destinationImage = images[destinationIndexPath.item]
            guard destinationImage.imageName != "placeholder" else { return }
            
            collectionView.performBatchUpdates({
                images.remove(at: sourceIndexPath.item)
                images.insert(image, at: destinationIndexPath.item)
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [destinationIndexPath])
            }) { _ in
                coordinator.drop(dropItem.dragItem, toItemAt: destinationIndexPath)
                self.save()
                
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
}

extension UIColor {
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}
