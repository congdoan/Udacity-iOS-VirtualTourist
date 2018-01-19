//
//  CoreDataStack.swift
//  VirtualTourist
//
//  Created by Cong Doan on 1/17/18.
//  Copyright © 2018 Cong Doan. All rights reserved.
//

import CoreData

// MARK: - CoreDataStack

struct CoreDataStack {
    
    // MARK: Properties
    
    internal let persistingContext: NSManagedObjectContext
    
    // MARK: Initializers
    
    init(modelName: String) {
        // Assumes the model is in the main bundle
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            fatalError("Unable to find \(modelName) in the main bundle")
        }
        
        // Try to create the model from the URL
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Unable to create a model from \(modelURL)")
        }
        
        // Create the Store Coordinator
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        // Create the Persisting Context and connect it to the Coordinator
        persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        persistingContext.persistentStoreCoordinator = coordinator
        
        // Add a SQLite store located in the documents folder
        let fm = FileManager.default
        guard let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to reach the documents folder")
        }
        let dbURL = docUrl.appendingPathComponent("model.sqlite")
        
        // Options for migration
        let options = [NSInferMappingModelAutomaticallyOption: true, NSMigratePersistentStoresAutomaticallyOption: true]
        
        do {
            try addStoreCoordinator(coordinator,
                                    storeType: NSSQLiteStoreType, configuration: nil,
                                    storeURL: dbURL, options: options as [NSObject : AnyObject]?)
        } catch {
            fatalError("Unable to add store at \(dbURL)")
        }
    }
    
    // MARK: Utils
    
    func addStoreCoordinator(_ coordinator: NSPersistentStoreCoordinator,
                             storeType: String, configuration: String?,
                             storeURL: URL, options : [NSObject:AnyObject]?) throws {
        try coordinator.addPersistentStore(ofType: storeType, configurationName: configuration, at: storeURL, options: options)
    }

}

// MARK: - CoreDataStack (CoreData-related methods)

extension CoreDataStack {
    
    typealias Batch = (_ workerContext: NSManagedObjectContext) -> ()
    
    func performBackgroundBatchOperation(_ batch: @escaping Batch) {
        persistingContext.perform {
            batch(self.persistingContext)
            self.saveAsync()
        }
    }
    
    func fetchPinsAsync(completionHandler: @escaping (_ pins: [Pin]) -> Void) {
        persistingContext.perform {
            do {
                let pins = try self.persistingContext.fetch(Pin.request())
                completionHandler(pins)
            } catch {
                fatalError("Error Async-Fetching Pin objects: \(error)")
            }
        }
    }

    func saveAsync() {
        if persistingContext.hasChanges {
            persistingContext.perform() {
                do {
                    try self.persistingContext.save()
                } catch {
                    fatalError("Error while saving Persisting Context: \(error)")
                }
            }
        }
    }

}
