//
//  ChatsViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 05/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import Firebase
import Kingfisher
import NVActivityIndicatorView
import UIKit

class ChatsViewController: UIViewController, UNUserNotificationCenterDelegate {
    
    //MARK: - Outlets
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var signedOutView: UIView!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet var activityView: NVActivityIndicatorView!
    @IBOutlet var loadingLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    
    
    //MARK: - Properties
    
    var chats: [Chat] = []
    var refHandle: DatabaseHandle!
    var ref: DatabaseReference!
    var authHandle: AuthStateDidChangeListenerHandle!
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss E, d MMM, yyyy"
        return formatter
    }()
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signInButton.layer.cornerRadius = Settings.cornerRadius
        loadingLabel.text = "Loading Chats..."
        ref = Database.database().reference()
        authHandle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            if user != nil {
                self.signedOutView.isHidden = true
                self.downloadChats()
                
            } else {
                self.chats.removeAll()
                self.signedOutView.isHidden = false
            }
        })
    }
    
    
    // MARK: - Helper Methods
    
    fileprivate func downloadChats() {
        self.showLoadingUI(true, for: self.activityView, label: self.loadingLabel, text: "Loading Chats...")
        let UID = Settings.currentUser!.uid
        
        refHandle = ref.child("users/\(UID)/chats").queryOrdered(byChild: "timestamp").observe(.value, with: { (dataSnapshot) in
            self.chats.removeAll()
            var newChats: [Chat] = []
            
            for child in dataSnapshot.children {
                if let snapshot = child as? DataSnapshot,
                    let chat = Chat(snapshot: snapshot) {
                    newChats.append(chat)
                }
            }
            
            self.showLoadingUI(false, for: self.activityView, label: self.loadingLabel, text: "Loading Chats...")
            self.chats = newChats.reversed()
            self.tableView.reloadData()
            self.infoLabel.text = self.chats.isEmpty ? "Your conversations will appear here once chatting begins." : ""
        })
    }
    
    
    // MARK: - Action Methods
    
    @IBAction func signInButtonTapped(_ sender: Any) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "SignInVC") {
            present(vc, animated: true)
        }
    }
}


// MARK: - TableView Delegates & Datasource

extension ChatsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        chats.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 2
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessagesCell", for: indexPath) as! MessagesTableViewCell
        let chat = chats[indexPath.section]
        cell.customImageView.image = nil
        cell.activityView.startAnimating()
        cell.customImageView.alpha = 1
        cell.customImageView.layer.cornerRadius = 30
        
        // If logged in user is advert owner, chat recipient is customer, if logged in user is customer, chat recipient would be advert owner
        let recipient = Auth.auth().currentUser?.uid == chat.advertOwnerUID ? chat.customerDisplayName : chat.advertOwnerDisplayName
        let you = chat.latestSender == Auth.auth().currentUser?.uid ? "You: " : ""
        
        cell.recipientLabel.text = recipient
        cell.advertTitleLabel.text = chat.title
        cell.latestMessageLabel.text = "\(you)\(chat.messageBody)"
        
        // If chat is unread and the latest sender of the message is not signed in user - display unread UI
        if #available(iOS 13.0, *) {
            cell.newMessageImageView.image = UIImage(systemName: "circle.fill")
        } else {
            cell.newMessageImageView.image = UIImage(named: "Circle Fill")
        }
        
        if chat.read == "false" && chat.latestSender != Auth.auth().currentUser?.uid {
            cell.newMessageImageView.isHidden = false
        } else {
            cell.newMessageImageView.isHidden = true
        }
        
        let circleLogo = self.renderCirlularImage(for: UIImage(named: "RentSpace Icon Small Black BG"))
        if chat.thumbnailURL != "" {
            
            Storage.storage().reference(forURL: chat.thumbnailURL).downloadURL { (url, error) in
                if let error = error {
                    print("Error downloading image: \(error.localizedDescription)")
                } else {
                    if let url = url {
                        let processor = DownsamplingImageProcessor(size: CGSize(width: 300, height: 300))
                        cell.activityView.stopAnimating()
                        cell.customImageView.kf.setImage(with: url, placeholder:(circleLogo),
                            options: [
                                .processor(processor),
                                .transition(.fade(0.4)),
                                .scaleFactor(UIScreen.main.scale),
                                .cacheOriginalImage
                            ])
                        {
                            result in
                            switch result {
                            case .success:
                                cell.customImageView.contentMode = .scaleAspectFill
                            case .failure(let error):
                                print("Job failed: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        } else {
            let image = UIImage(named: "RentSpace Icon Small Black BG")
            cell.activityView.stopAnimating()
            cell.customImageView.alpha = 1
            cell.customImageView.image = renderCirlularImage(for: image)
        }
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "MessageVC") as! MessageViewController
        let chat = chats[indexPath.section]
        vc.chat = chat
        vc.viewingExistingChat = true
        vc.chatID = chat.chatID
        
        if chat.latestSender != Auth.auth().currentUser?.displayName {
            vc.messageRead = "true"
        }
        
        let cell = tableView.cellForRow(at: indexPath) as! MessagesTableViewCell
        if let image = cell.customImageView.image {
            vc.thumbnail = image
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let chat = chats[indexPath.section]
        
        if editingStyle == .delete {
            let ac = UIAlertController(title: "Delete Chat", message: "Are you sure you wish to permanently delete this conversation?", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                
                let childUpdates = ["users/\(chat.customerUID)/chats/\(chat.chatID)": NSNull(),
                                    "users/\(chat.advertOwnerUID)/chats/\(chat.chatID)": NSNull(),
                                    "messages/\(chat.chatID)": NSNull()]
                
                self.ref.updateChildValues(childUpdates) { (error, databaseRef) in
                    if error != nil {
                        print(error?.localizedDescription as Any)
                        self.showAlert(title: "Woah", message: "There was a problem deleting your conversation, please try again.")
                    }
                    print("Deletion completion")
                }
            }))
            ac.addAction(UIAlertAction(title: "Cancel", style: .default))
            present(ac, animated: true)
        }
    }
}
