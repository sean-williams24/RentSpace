//
//  AddPhotosViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 27/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit
import CoreData

class AddPhotosViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var imagesButton: UIBarButtonItem!
    
    var images = [Image]()
    let placeHolderImage = UIImage(named: "imagePlaceholder")
    private let itemsPerRow: CGFloat = 3
    private let sectionInsets = UIEdgeInsets(top: 15.0,
                                             left: 15.0,
                                             bottom: 15.0,
                                             right: 15.0)

    override func viewDidLoad() {
        super.viewDidLoad()


        // Load saved images into images array
        if let imageData = UserDefaults.standard.data(forKey: "Images") {
            do {
                let jsonDecoder = JSONDecoder()
                images = try jsonDecoder.decode([Image].self, from: imageData)
            } catch {
                print("Data could not be decoder: \(error)")
            }
        }
        
        // If there are no saved images, load in 9 placeholders
        if images.isEmpty {
            for _ in 0...8 {
                writeImageFileToDisk(image: placeHolderImage!, name: "placeholder", at: 0)
            }
        }

        print(images.count)
        

        
        if !photoAlbumIsFull() {
            addPhotosAlertController()
        } else {
            imagesButton.isEnabled = false
        }
        imagesButton.isEnabled = true
    }
    

    
    
    
    //MARK: - Private methods
    
    fileprivate func addPhotosAlertController() {
        let ac = UIAlertController(title: "Add some photos", message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            ac.addAction(UIAlertAction(title: "Camera", style: .default, handler: addPhotosFromCamera))
        }
        ac.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: addPhotosFromLibrary(action:)))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = ac.popoverPresentationController {
                       popoverController.sourceView = self.view //to set the source of your alert
                       popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY + 20, width: 30, height: 30) // you can set this as per your requirement.
                       popoverController.permittedArrowDirections = [] //to hide the arrow of any particular direction
                   }
        
        present(ac, animated: true)
    }
    
    func getDocumentsDirectory() -> URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return path[0]
    }
    
    //Encode photos array to json data and save to user defaults
    func save() {
        let jsonEncoder = JSONEncoder()
        
        if let savedData = try? jsonEncoder.encode(images) {
            UserDefaults.standard.set(savedData, forKey: "Images")
        }
    }
    
    func writeImageFileToDisk(image: UIImage, name imageName: String, at position: Int) {
        let filePath = getDocumentsDirectory().appendingPathComponent(imageName)
        
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            try? imageData.write(to: filePath)
        }
        print(images.count)
        let savingImage = Image(imageName: imageName)
        images.insert(savingImage, at: position)
    }
    
    fileprivate func photoAlbumIsFull() -> Bool {
        var imageNames = [String]()
        for image in images {
            imageNames.append(image.imageName)
        }
        
        if !imageNames.contains("placeholder") {
            return true
        }
        return false
    }
    
    
    //MARK: - Image Picker Delegates
    
    func addPhotosFromCamera(action: UIAlertAction) {
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.cameraCaptureMode = .photo
        picker.sourceType = .camera
        present(picker, animated: true)
    }
    
    func addPhotosFromLibrary(action: UIAlertAction) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        let imageName = UUID().uuidString

        writeImageFileToDisk(image: image, name: imageName, at: 0)

        images.removeLast()
        save()
        collectionView.reloadData()
        dismiss(animated: true)
        
        if photoAlbumIsFull() {
            imagesButton.isEnabled = false
        }
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tappedImage = images[indexPath.item]
        
        if tappedImage.imageName != "placeholder" {
            images.remove(at: indexPath.item)
            save()
            writeImageFileToDisk(image: placeHolderImage!, name: "placeholder", at: images.count)
            collectionView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        
    }
    
    //MARK: - Action Methods
    
    
    @IBAction func addPhotosTapped(_ sender: Any) {
        addPhotosAlertController()
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

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
