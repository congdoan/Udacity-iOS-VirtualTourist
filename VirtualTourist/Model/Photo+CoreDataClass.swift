//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Cong Doan on 1/15/18.
//  Copyright © 2018 Cong Doan. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {
    
    // MARK: Initializer
    
    convenience init(data: Data, pin: Pin, context: NSManagedObjectContext) {
        if let entityDescription = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: entityDescription, insertInto: context)
            self.data = data
            self.pin = pin
        } else {
            fatalError("Unable to find Entity name!")
        }
    }

}
