//
//  Extension.swift
//  RealTimeChat
//
//  Created by iosadmin on 12.6.2018.
//  Copyright © 2018 iosadmin. All rights reserved.
//

import UIKit

let imageCache = NSCache<NSString, UIImage>()

extension UIImageView {
    func loadImageUsingCacheWithUrlString(urlString: String) {
        
        self.image = nil
        
        //check cache for images first
        if let cachedImage = imageCache.object(forKey: urlString as NSString) {
            self.image = cachedImage
            return
        }
        
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            
            if error != nil {
                print(error!)
                return
            }
            
            DispatchQueue.main.async {
                if let dowloadedImage = UIImage(data: data!) {
                    imageCache.setObject(dowloadedImage, forKey: urlString as NSString)
                    self.image = dowloadedImage
                }
            }
            
        }).resume()
    }
}
