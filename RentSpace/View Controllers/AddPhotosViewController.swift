//
//  AddPhotosViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 27/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit

class AddPhotosViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    

    var images = [UIImage]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for _ in 0...8 {
            let image = UIImage(named: "imagePlaceholder")
            images.append(image!)
        }
        
        let space: CGFloat = 3.0
        let size = (view.frame.size.width - (2 * space)) / 3.0

        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSize(width: size, height: size)
        
        addPhotosAlertController()
        
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
        
        images.insert(image, at: 0)
        images.removeLast()
        collectionView.reloadData()
        dismiss(animated: true)
    }
    
    
    //MARK: - Collection View delegates and data source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Photo cell", for: indexPath) as! PhotoCollectionViewCell
        
        
        cell.cellImageView.image = images[indexPath.row]
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
