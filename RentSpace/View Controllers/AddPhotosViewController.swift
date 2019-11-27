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
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet var imagesButton: UIBarButtonItem!
    
    var images = [Image]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let space: CGFloat = 3.0
        let size = (view.frame.size.width - (2 * space)) / 3.0

        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSize(width: size, height: size)
          
        if images.isEmpty {
            for _ in 0...8 {
                let image = UIImage(named: "imagePlaceholder")
                writeImageFileToDisk(image: image!, name: "placeholder")
            }
        }

        // Load saved images into images array
        if let imageData = UserDefaults.standard.data(forKey: "Images") {
            do {
                let jsonDecoder = JSONDecoder()
                images = try jsonDecoder.decode([Image].self, from: imageData)
            } catch {
                print("Data could not be decoder: \(error)")
            }
        }

        
        if !photoAlbumIsFull() {
            addPhotosAlertController()
            print("Were in")
        } else {
            imagesButton.isEnabled = false
        }
    }
    
    //MARK: - Private methods
    
    fileprivate func addPhotosAlertController() {
        let ac = UIAlertController(title: "Add some photos", message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            ac.addAction(UIAlertAction(title: "Camera", style: .default, handler: addPhotosFromCamera))
        }
        ac.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: addPhotosFromLibrary(action:)))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
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
    
    func writeImageFileToDisk(image: UIImage, name imageName: String) {
        let filePath = getDocumentsDirectory().appendingPathComponent(imageName)
        
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            try? imageData.write(to: filePath)
        }
        
        let savingImage = Image(imageName: imageName)
        images.insert(savingImage, at: 0)
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

        writeImageFileToDisk(image: image, name: imageName)

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
        let image = images[indexPath.row]
    
        let savedImageFile = getDocumentsDirectory().appendingPathComponent(image.imageName)
        cell.cellImageView.image = UIImage(contentsOfFile: savedImageFile.path)
        
        return cell
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
