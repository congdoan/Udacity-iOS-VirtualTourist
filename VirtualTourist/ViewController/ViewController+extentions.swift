//
//  ViewController+extentions.swift
//  VirtualTourist
//
//  Created by Cong Doan on 1/17/18.
//  Copyright © 2018 Cong Doan. All rights reserved.
//

import UIKit

extension UIViewController {
    
    var coreDataStack: CoreDataStack {
        return (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    }
    
}
