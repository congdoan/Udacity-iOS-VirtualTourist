//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Cong Doan on 1/15/18.
//  Copyright © 2018 Cong Doan. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Pin)
public class Pin: NSManagedObject {
    
    // MARK: Initializer
    
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let entityDescription = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: entityDescription, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Unable to find Entity name 'Pin'!")
        }
    }

}
