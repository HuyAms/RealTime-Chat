//
//  ViewController.swift
//  RealTimeChat
//
//  Created by iosadmin on 5.6.2018.
//  Copyright © 2018 iosadmin. All rights reserved.
//

import UIKit
import Firebase

class MessageController: UITableViewController {
    
    let cellId = "cellId"
    
    var messages = [Message]()
    var messageDictionary = [String: Message]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLoggedIn()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        tableView.allowsMultipleSelectionDuringEditing = true
        
//        observeMessages()
        
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let message = self.messages[indexPath.row]
        
        if let chatPartnerId = message.chatPartnerId() {
            Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue(completionBlock: { (error, ref) in
                if error != nil {
                    print("Failed to delete message: ", error!)
                    return
                }
                
                
                self.messageDictionary.removeValue(forKey: chatPartnerId)
                self.attemptReloadOfTable()
                
                //this is one way of updating the table, but its actually not that safe
//                self.messages.remove(at: indexPath.row)
//                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            })
        }
        
    }
    
    func observeUserMessage() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference().child("user-messages").child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            let userId = snapshot.key
            
            Database.database().reference().child("user-messages").child(uid).child(userId).observe(.childAdded, with: { (snapshot) in
                let messageId = snapshot.key
                self.fetchMessageWithMessageId(messageId: messageId)
  
            }, withCancel: nil)
            })
    }
    
    private func fetchMessageWithMessageId(messageId: String) {
        let messageReference = Database.database().reference().child("messages").child(messageId)
        messageReference.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let message = Message(dictionary: dictionary)
                
                if let chatPartnerId = message.chatPartnerId() {
                    self.messageDictionary[chatPartnerId] = message
                }
                
                self.attemptReloadOfTable()
            }
        }, withCancel: nil)
    }
    
    var timer: Timer?
    private func attemptReloadOfTable() {
        
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
    }
    
    @objc func handleReloadTable() {
        
        self.messages = Array(self.messageDictionary.values)
        self.messages.sort(by: { (m1, m2) -> Bool in
            return m1.timestamp! > m2.timestamp!
        })
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func observeMessages() {
        let ref = Database.database().reference().child("messages")
        ref.observe(.childAdded, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let message = Message(dictionary: dictionary)
                
                if let toId = message.toId {
                    self.messageDictionary[toId] = message
                    self.messages = Array(self.messageDictionary.values)
                    self.messages.sort(by: { (m1, m2) -> Bool in
                        return m1.timestamp! > m2.timestamp!
                    })
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }, withCancel: nil)
        
        ref.observe(.childRemoved) { (snapshot) in
            self.messageDictionary.removeValue(forKey: snapshot.key)
            self.attemptReloadOfTable()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        let message = messages[indexPath.row]
        cell.message = message
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        
        guard let chatPartnerId = message.chatPartnerId() else {
            return
        }
        
        let ref = Database.database().reference().child("users").child(chatPartnerId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String : AnyObject] {
                var user = User()
                user.email = dictionary["email"] as? String
                user.name = dictionary["name"] as? String
                user.profileImageUrl = dictionary["profileImageUrl"] as? String
                user.id = snapshot.key
                self.showChatControllerForUser(user: user)
            }
        }, withCancel: nil)
    }
    
    func showChatControllerForUser(user: User) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
    func checkIfUserIsLoggedIn() {
        //User is not logged in
        if Auth.auth().currentUser?.uid == nil {
            handleLogout()
        } else {
            fetchUserAndSetupNavBarTitle()
        }
    }
    
    func setupNavBarWithUser(user: User) {
        messages.removeAll()
        messageDictionary.removeAll()
        tableView.reloadData()
        
        observeUserMessage()
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(containerView)

        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true

        if let profileImageUrl = user.profileImageUrl {
            profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }

        containerView.addSubview(profileImageView)

        //ios 9 constraint anchors
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let nameLabel = UILabel()

        containerView.addSubview(nameLabel)

        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        //need x, y, width, height anchors
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true

        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
        self.navigationItem.titleView = titleView

    }
    
    func fetchUserAndSetupNavBarTitle() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                var user = User()
                user.email = dictionary["email"] as? String
                user.name = dictionary["name"] as? String
                user.profileImageUrl = dictionary["profileImageUrl"] as? String
                self.setupNavBarWithUser(user: user)
            }
        })
    }
    
    @objc func handleNewMessage() {
        let newMessageController = NewMessageController()
        newMessageController.messagesController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    
    @objc func handleLogout() {
        do {
            try Auth.auth().signOut()

        } catch let loggoutError {
            print(loggoutError)
        }
        
        let loginController = LoginController()
        loginController.messageController = self 
        present(loginController, animated: true, completion: nil)
    }



}



