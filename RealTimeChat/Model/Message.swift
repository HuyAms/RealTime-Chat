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
    var imageWidth: Double?
    var imageHeight: Double?
    let videoUrl: String?
    
    func chatPartnerId() -> String? {
        let chatPartnerId: String?
        
        if fromId == Auth.auth().currentUser?.uid {
            chatPartnerId = toId
        } else {
            chatPartnerId = fromId
        }
        return chatPartnerId
    }
    
    init(dictionary: [String: AnyObject]) {
        fromId = dictionary["fromId"] as? String
        toId = dictionary["toId"] as? String
        text = dictionary["text"] as? String
        timestamp = dictionary["timestamp"] as? Int
        imageUrl = dictionary["imageUrl"] as? String
        imageWidth = dictionary["imageWidth"] as? Double
        imageHeight = dictionary["imageHeight"] as? Double
        videoUrl = dictionary["videoUrl"] as? String
    }
}
