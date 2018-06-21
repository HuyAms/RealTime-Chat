//
//  ChatLogController.swift
//  RealTimeChat
//
//  Created by iosadmin on 14.6.2018.
//  Copyright © 2018 iosadmin. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation
import Firebase

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let cellId = "cellId"
    var messages = [Message]()
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            
            observeMessages()
        }
    }
    
    func observeMessages() {
        guard let uid = Auth.auth().currentUser?.uid, let userId = user?.id else {
            return
        }
        
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(userId)
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            let messageId = snapshot.key
            let messagesRef = Database.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let dictionary = snapshot.value as? [String:AnyObject] else {
                    return
                }
                
                let message = Message(dictionary: dictionary)
                
                self.messages.append(message)
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    //scroll to the last index
                    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                }
            }, withCancel: nil)
        }, withCancel: nil)
    }
    
    
    lazy var inputTextField: UITextField = {
        let inputTextField = UITextField()
        inputTextField.placeholder = "Enter message ..."
        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        inputTextField.delegate = self
        return inputTextField
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 58, right: 0)
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)

//        collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = UIColor.white
        collectionView?.keyboardDismissMode = .interactive
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        
//        setupInputComponents()
//
//        setupKeyboardObservers()
    }
    
    lazy var inputContainerView: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        
        let uploadImageView = UIImageView()
        uploadImageView.isUserInteractionEnabled = true
        uploadImageView.image = UIImage(named: "uploadimage")
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.contentMode = .scaleAspectFill
        uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadTap)))
        containerView.addSubview(uploadImageView)
        
        uploadImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        
        containerView.addSubview(sendButton)
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        containerView.addSubview(self.inputTextField)
        self.inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 8).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: 8).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLineView)
        
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        containerView.backgroundColor = UIColor.white
        
        return containerView
    }()
    
    @objc func handleUploadTap() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        present(imagePickerController, animated: true, completion: nil)
    }
    
    override var inputAccessoryView: UIView? {
        get {
         return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
           NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func handleKeyboardWillHide(notification: Notification) {
        let keyboardDuration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        containerViewBottomAnchor?.constant = 0
        
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func handleKeyboardWillShow(notification: Notification) {
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardDuration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        
        //move the input area up
        containerViewBottomAnchor?.constant = -keyboardFrame.height
        
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        //We selected video
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL {
           handleVideoSelectedForUrl(videoUrl: videoUrl)
        } else {
            //We selected image
            handleImageSelectedForInfo(info: info)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func handleVideoSelectedForUrl(videoUrl: URL) {
        let filename = NSUUID().uuidString + ".mov"
        let uploadTask = Storage.storage().reference().child("message_movies").child(filename).putFile(from: videoUrl, metadata: nil, completion: { (metadata,error) in
            
            if error != nil {
                print("Failed to upload of video: ", error!)
            }
            
            if let storageUrl = metadata?.downloadURL()?.absoluteString {
                if let thumbnailImage = self.thumbnailImageForVideoUrl(fileUrl: videoUrl) {
                    self.uploadToFirebaseStorageUsingImage(image: thumbnailImage, completion: { (imageUrl) in
                        self.sendMessageWithVideoUrl(videoUrl: storageUrl, thumbnailImage: thumbnailImage, imageUrl: imageUrl)
                    })
                }
            
            }
        })
        
        uploadTask.observe(.progress) { (snapshot) in
            if let completedUnitCount = snapshot.progress?.completedUnitCount {
                self.navigationItem.title = String(completedUnitCount)
            }
        }
        
        uploadTask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }
    }
    
    private func sendMessageWithVideoUrl(videoUrl: String, thumbnailImage: UIImage, imageUrl: String) {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        if let user = user, let toId = user.id, let fromId = Auth.auth().currentUser?.uid {
            let timestamp: Int = Int(NSDate().timeIntervalSince1970)
            let values = ["toId": toId, "fromId": fromId, "timestamp": timestamp, "videoUrl": videoUrl, "imageUrl": imageUrl, "imageWidth": thumbnailImage.size.width, "imageHeight": thumbnailImage.size.height] as [String : Any]
            
            childRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
                if error != nil {
                    print(error!)
                    return
                }
                
                self.inputTextField.text = nil
                
                let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
                
                let messageId = childRef.key
                userMessagesRef.updateChildValues([messageId: 1])
                
                let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
                recipientUserMessagesRef.updateChildValues([messageId: 1])
            })
        }
    }
    
    private func thumbnailImageForVideoUrl(fileUrl: URL) -> UIImage? {
        let asset = AVAsset(url: fileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)
        } catch let err {
            print(err)
        }
        
        return nil
    }
    
    private func handleImageSelectedForInfo(info: [String : Any]) {
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEdittedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadToFirebaseStorageUsingImage(image: selectedImage, completion: { (imageUrl) in
                self.sendMessageWithImageUrl(imageUrl: imageUrl, image: selectedImage)
            })
        }
    }
    
    private func uploadToFirebaseStorageUsingImage(image: UIImage, completion: @escaping (_ imageUrl: String) -> Void)  {
        let imageName = NSUUID().uuidString
        let ref = Storage.storage().reference().child("message_images").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
            ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print("Failed to upload image: ", error!)
                    return
                }
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    completion(imageUrl)
                }
            })
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId ,for: indexPath) as! ChatMessageCell
        
        cell.chatLogController = self
        
        let message = messages[indexPath.item]
        cell.textView.text = message.text
        
        setUpCell(cell: cell, message: message)
        
        //modify the bubbleView's width
        if let text = message.text  {
            cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: text).width + 32
            cell.textView.isHidden = false
        } else if message.imageUrl != nil {
            cell.textView.isHidden = true
            cell.bubbleWidthAnchor?.constant = 200
            cell.bubbleView.backgroundColor = UIColor.clear
        }
        
        return cell
    }
    
    private func setUpCell(cell: ChatMessageCell, message: Message) {
        if let profileImageUrl = self.user?.profileImageUrl {
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        if let messageImageUrl = message.imageUrl {
            cell.bubbleView.backgroundColor = UIColor.clear
            cell.messageImageView.isHidden = false
            cell.messageImageView.loadImageUsingCacheWithUrlString(urlString: messageImageUrl)
        } else {
            cell.messageImageView.isHidden = true
        }
        
        if message.fromId == Auth.auth().currentUser?.uid {
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white

            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
            cell.profileImageView.isHidden = true
        } else {
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = UIColor.black
            
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
            cell.profileImageView.isHidden = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        
        //get estimated height
        let message = messages[indexPath.item]
        if let text = message.text {
            height = estimateFrameForText(text: text).height + 20
        } else if let imageWidth = message.imageWidth, let imageHeight = message.imageHeight {
            height =  CGFloat(imageHeight / imageWidth * 200)
        }
        
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    private func estimateFrameForText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    var containerViewBottomAnchor: NSLayoutConstraint?
    
//    func setupInputComponents() {
//        let containerView = UIView()
//        containerView.backgroundColor = UIColor.white
//        containerView.translatesAutoresizingMaskIntoConstraints = false
//        
//        view.addSubview(containerView)
//        
//        containerView.addSubview(inputTextField)
//
//        
//        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
//        
//        containerViewBottomAnchor = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        containerViewBottomAnchor?.isActive = true
//        
//        containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
//        containerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
//        
//        let sendButton = UIButton(type: .system)
//        sendButton.setTitle("Send", for: .normal)
//        sendButton.translatesAutoresizingMaskIntoConstraints = false
//        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
//        
//        containerView.addSubview(sendButton)
//        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
//        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
//        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
//        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
//    
//        
//        inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
//        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
//        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: 8).isActive = true
//        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
//        
//        let separatorLineView = UIView()
//        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
//        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
//        containerView.addSubview(separatorLineView)
//        
//        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
//        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
//        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
//        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
//    }
//    
    @objc func handleSend() {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        if let user = user, let toId = user.id, let fromId = Auth.auth().currentUser?.uid {
            let timestamp: Int = Int(NSDate().timeIntervalSince1970)
            let values = ["text": inputTextField.text!, "toId": toId, "fromId": fromId, "timestamp": timestamp] as [String : Any]

            childRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
                if error != nil {
                    print(error!)
                    return
                }
                
                self.inputTextField.text = nil
                
                let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
                
                let messageId = childRef.key
                userMessagesRef.updateChildValues([messageId: 1])
                
                let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
                recipientUserMessagesRef.updateChildValues([messageId: 1])
            })
        }
    }
    
    private func sendMessageWithImageUrl(imageUrl: String, image: UIImage) {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        if let user = user, let toId = user.id, let fromId = Auth.auth().currentUser?.uid {
            let timestamp: Int = Int(NSDate().timeIntervalSince1970)
            let values = ["toId": toId, "fromId": fromId, "timestamp": timestamp, "imageUrl": imageUrl, "imageHeight": image.size.height, "imageWidth":image.size.width] as [String : Any]
            
            childRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
                if error != nil {
                    print(error!)
                    return
                }
                
                self.inputTextField.text = nil
                
                let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
                
                let messageId = childRef.key
                userMessagesRef.updateChildValues([messageId: 1])
                
                let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
                recipientUserMessagesRef.updateChildValues([messageId: 1])
            })
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
    
    
    var startingFrame: CGRect?
    var blackBackgroundView: UIView?
    var startingImageView: UIImageView?
    
    //my custom zooming logic
    func perormZoomInForImageView(startingIImageView: UIImageView) {
        self.startingImageView = startingIImageView
        self.startingImageView?.isHidden = true
        
        startingFrame = startingIImageView.superview?.convert(startingIImageView.frame, to: nil)
        
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.backgroundColor = UIColor.red
        zoomingImageView.image = startingIImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            blackBackgroundView = UIView(frame: keyWindow.frame)
            blackBackgroundView?.backgroundColor = UIColor.black
            blackBackgroundView?.alpha = 0
            
            keyWindow.addSubview(blackBackgroundView!)
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                self.blackBackgroundView?.alpha = 1
                self.inputContainerView.alpha = 0
                
                let height = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomingImageView.center = keyWindow.center
            }, completion: nil)
        }
    }
    
    @objc func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        if let zoomOutImageView = tapGesture.view {
            //need to animate back out to controller
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                self.blackBackgroundView?.alpha = 0
                self.inputContainerView.alpha = 1
                zoomOutImageView.frame = self.startingFrame!
            }, completion: { (completed: Bool) in
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
            })
            
        }
    }
}
