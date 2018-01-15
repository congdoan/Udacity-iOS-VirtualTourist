//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Cong Doan on 1/15/18.
//  Copyright © 2018 Cong Doan. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    //@NSManaged public var data: NSData?
    @NSManaged public var data: Data?
    @NSManaged public var pin: Pin?

}
