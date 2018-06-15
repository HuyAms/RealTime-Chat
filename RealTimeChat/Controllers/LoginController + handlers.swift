//
//  LoginController + handlers.swift
//  RealTimeChat
//
//  Created by iosadmin on 12.6.2018.
//  Copyright © 2018 iosadmin. All rights reserved.
//

import UIKit
import Firebase

extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @objc func handleSelectProfileImageView() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEdittedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)

    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func handleRegister() {
        guard let email = emailTextField.text, let password = passwordTextField.text, let username = nameTextField.text else {
            print("Form is not valid")
            return
        }
        
        if loginRegisterSegmentControl.selectedSegmentIndex == 0 {
            handleLogin(email: email, password: password)
        } else {
            handleLoginRegister(email: email, password: password, username: username)
        }
    }
    
    func handleLogin(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
            if error != nil {
                print(error!)
                return
            }
            
            self.messageController?.fetchUserAndSetupNavBarTitle()
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    func handleLoginRegister(email: String, password: String, username: String) {
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if error != nil {
                print(error!)
                return
            }
            
            guard let uid = user?.uid else {
                return
            }
            
            //successfully authenticated user
            let imageName = NSUUID().uuidString
            let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).jpg")
            if let profileImage = self.profileImageView.image, let uploadData = UIImageJPEGRepresentation(profileImage, 0.1) {
                storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                    if error != nil {
                        print(error!)
                        return
                    }
                    
                    if let imgUrl = metadata?.downloadURL()?.absoluteString {
                        let values = ["name": username, "email": email, "profileImageUrl": imgUrl]
                        
                        self.registerUserIntoDatabaseWithUID(uid: uid, values: values)
                    }
                
                })
            }
         

        }
    }
    
    private func registerUserIntoDatabaseWithUID(uid: String, values: [AnyHashable: Any] ) {
        let ref = Database.database().reference(fromURL: "https://realtimechat-49044.firebaseio.com/")
        let userRef = ref.child("users").child(uid)
        
        userRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print(error!)
                return
            }
            
//            self.messageController?.fetchUserAndSetupNavBarTitle()
            var user = User()
            user.email = values["email"] as? String
            user.name = values["name"] as? String
            user.profileImageUrl = values["profileImageUrl"] as? String
            self.messageController?.setupNavBarWithUser(user: user)
            
            self.dismiss(animated: true, completion: nil)
        })
        
    }
    
}


