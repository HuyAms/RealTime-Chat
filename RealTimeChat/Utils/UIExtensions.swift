//
//  UIExtensions.swift
//  RealTimeChat
//
//  Created by iosadmin on 5.6.2018.
//  Copyright © 2018 iosadmin. All rights reserved.
//

import UIKit

extension UIColor {
    
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }
}
