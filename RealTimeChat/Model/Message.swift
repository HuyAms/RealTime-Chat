//
//  Message.swift
//  RealTimeChat
//
//  Created by iosadmin on 15.6.2018.
//  Copyright © 2018 iosadmin. All rights reserved.
//

import Foundation
import Firebase

struct Message {
    var fromId: String?
    var text: String?
    var timestamp: Int?
    var toId: String?
    var imageUrl: String?
    
    func chatPartnerId() -> String? {
        let chatPartnerId: String?
        
        if fromId == Auth.auth().currentUser?.uid {
            chatPartnerId = toId
        } else {
            chatPartnerId = fromId
        }
        return chatPartnerId
    }
}
