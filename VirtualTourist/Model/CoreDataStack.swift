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
    
    private let context: NSManagedObjectContext
    private let persistingContext: NSManagedObjectContext
    
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
        
        // Create the Persisting Context and connect it to the Store Coordinator
        persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        persistingContext.persistentStoreCoordinator = coordinator
        // Create the Main Context and connect it to the Persisting Context
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = persistingContext

        // Add a SQLite store located in the documents folder
        let fm = FileManager.default
        guard let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to reach the documents folder")
        }
        let dbURL = docUrl.appendingPathComponent("model.sqlite")
        
        // Options for migration
        let options = [NSInferMappingModelAutomaticallyOption: true, NSMigratePersistentStoresAutomaticallyOption: true]
        
        // Add Persistent Store
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: options)
        } catch {
            fatalError("Unable to add store at \(dbURL)")
        }
    }
    
}

// MARK: - CoreDataStack (CoreData-related methods)

extension CoreDataStack {
    
    func fetchPins(completionHandler: @escaping ([Pin]) -> Void) {
        context.perform {
            do {
                let pins = try self.context.fetch(Pin.request())
                completionHandler(pins)
            } catch {
                fatalError("Error while fetching Pin objects")
            }
        }
    }
    
    typealias Operation = (_ context: NSManagedObjectContext) -> Void

    func performOperation(_ operation: @escaping Operation) {
        context.perform {
            operation(self.context)

            if self.context.hasChanges {
                self.save()
            }
        }
    }

    private func save() {
        do {
            // Commit unsaved changes to the Persisting Context
            try context.save()
        } catch {
            fatalError("Error while saving the Main Context")
        }
        
        // Save unsaved changes to the Persistent Store on the Persisting Context's private queue
        persistingContext.perform {
            do {
                try self.persistingContext.save()
            } catch {
                fatalError("Error while saving the Persisting Context")
            }
        }
    }
    
}
