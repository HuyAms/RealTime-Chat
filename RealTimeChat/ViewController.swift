//
//  ViewController.swift
//  RealTimeChat
//
//  Created by iosadmin on 5.6.2018.
//  Copyright © 2018 iosadmin. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
 
        //User is not logged in
        if Auth.auth().currentUser?.uid == nil {
            handleLogout()
        }
    }
    
    @objc func handleLogout() {
        do {
            try Auth.auth().signOut()

        } catch let loggoutError {
            print(loggoutError)
        }
        
        let loginController = LoginController()
        present(loginController, animated: true, completion: nil)
    }



}



