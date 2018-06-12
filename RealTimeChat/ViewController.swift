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
 
    }
    
    @objc func handleLogout() {
        let loginController = LoginController()
        present(loginController, animated: true, completion: nil)
    }



}



