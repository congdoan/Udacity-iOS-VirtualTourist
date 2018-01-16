//
//  Pin+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Cong Doan on 1/15/18.
//  Copyright © 2018 Cong Doan. All rights reserved.
//
//

import Foundation
import CoreData


extension Pin {

    /*
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pin> {
        return NSFetchRequest<Pin>(entityName: "Pin")
    }
    */

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    //@NSManaged public var photos: NSSet?
    @NSManaged public var photos: Set<Photo>?

}

// MARK: Generated accessors for photos
extension Pin {

    @objc(addPhotosObject:)
    @NSManaged public func addToPhotos(_ value: Photo)

    @objc(removePhotosObject:)
    @NSManaged public func removeFromPhotos(_ value: Photo)

    @objc(addPhotos:)
    //@NSManaged public func addToPhotos(_ values: NSSet)
    @NSManaged public func addToPhotos(_ values: Set<Photo>)

    @objc(removePhotos:)
    //@NSManaged public func removeFromPhotos(_ values: NSSet)
    @NSManaged public func removeFromPhotos(_ values: Set<Photo>)

}
