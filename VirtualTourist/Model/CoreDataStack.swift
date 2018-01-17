//
//  CoreDataStack.swift
//
//
//  Created by Fernando Rodríguez Romero on 21/02/16.
//  Copyright © 2016 udacity.com. All rights reserved.
//

import CoreData

// MARK: - CoreDataStack

struct CoreDataStack {
    
    // MARK: Properties
    
    private let model: NSManagedObjectModel
    internal let coordinator: NSPersistentStoreCoordinator
    private let modelURL: URL
    internal let dbURL: URL
    internal let persistingContext: NSManagedObjectContext
    internal let backgroundContext: NSManagedObjectContext
    let context: NSManagedObjectContext
    
    // MARK: Initializers
    
    init?(modelName: String) { 
        // Assumes the model is in the main bundle
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            print("Unable to find \(modelName) in the main bundle")
            return nil
        }
        self.modelURL = modelURL
        
        // Try to create the model from the URL
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            print("Unable to create a model from \(modelURL)")
            return nil
        }
        self.model = model
        
        // Create the Store Coordinator
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        /* Information flows from child to parent */
        /* Background Context(private queue) -> Main Context(main queue) -> Persisting Context(private queue) -> Store Coordinator */
        // Create a Persisting Context and connect it to the Coordinator
        persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        persistingContext.persistentStoreCoordinator = coordinator
        // Create a Main Context whose parent is the Persisting Context
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = persistingContext
        // Create a Background Context whose parent is the Main Context
        backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = context
        
        // Add a SQLite store located in the documents folder
        let fm = FileManager.default
        guard let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to reach the documents folder")
            return nil
        }
        self.dbURL = docUrl.appendingPathComponent("model.sqlite")
        
        // Options for migration
        let options = [NSInferMappingModelAutomaticallyOption: true, NSMigratePersistentStoresAutomaticallyOption: true]
        
        do {
            try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: options as [NSObject : AnyObject]?)
        } catch {
            print("Unable to add store at \(dbURL)")
        }
    }
    
    // MARK: Utils
    
    func addStoreCoordinator(_ storeType: String, configuration: String?, storeURL: URL, options : [NSObject:AnyObject]?) throws {
        try coordinator.addPersistentStore(ofType: storeType, configurationName: configuration, at: storeURL, options: options)
    }

}

// MARK: - CoreDataStack (Batch Processing in the Background)

extension CoreDataStack {
    
    typealias Batch = (_ workerContext: NSManagedObjectContext) -> ()
    
    func performBackgroundBatchOperation(_ batch: @escaping Batch) {
        backgroundContext.perform() {
            batch(self.backgroundContext)
            
            // Save it to the Parent Context, so normal saving can work
            do {
                try self.backgroundContext.save()
            } catch {
                fatalError("Error while saving Background Context: \(error)")
            }
        }
    }

}

// MARK: - CoreDataStack (Save Data)

extension CoreDataStack {

    func save() {
        // We call this synchronously, but it's a very fast
        // operation (it doesn't hit the disk). We need to know
        // when it ends so we can call the next save (on the persisting
        // context). This last one might take some time and is done
        // in a background queue
        context.performAndWait() {
            if self.context.hasChanges {
                do {
                    try self.context.save()
                } catch {
                    fatalError("Error while saving Main Context: \(error)")
                }
                
                //DEBUG
                print("CoreDataStack.save() Thread.current     : \(Thread.current)")
                print("CoreDataStack.save() Thread.isMainThread: \(Thread.isMainThread)")

                // Now we save in the background
                self.persistingContext.perform() {
                    do {
                        try self.persistingContext.save()
                    } catch {
                        fatalError("Error while saving Persisting Context: \(error)")
                    }
                }
            }
        }
    }
    
    func autoSave(_ delayInSeconds : Int) {
        if delayInSeconds > 0 {
            do {
                try self.context.save()
                print("Autosaving Main Context")
            } catch {
                print("Error while Autosaving Main Context")
            }
            
            let delayInNanoSeconds = UInt64(delayInSeconds) * NSEC_PER_SEC
            let time = DispatchTime.now() + Double(Int64(delayInNanoSeconds)) / Double(NSEC_PER_SEC)
            
            DispatchQueue.main.asyncAfter(deadline: time) {
                self.autoSave(delayInSeconds)
            }
        }
    }

}
// MARK: - CoreDataStack (Fetch Data)

extension CoreDataStack {
    
    func fetchPinsAsync(completionHandler: @escaping (_ pins: [Pin]) -> Void) {
        // Initialize Asynchronous Fetch Request
        let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: Pin.request()) { (asyncResult) in
            if let pins = asyncResult.finalResult {
                completionHandler(pins)
            } else {
                completionHandler([Pin]())
            }
        }
        
        // Execute Asynchronous Fetch Request using a Background (Private-Queue) Context
        do {
            //try persistingContext.execute(asyncRequest)
            try backgroundContext.execute(asyncRequest)
        } catch {
            fatalError("Error Async-Fetching Pin objects: \(error)")
        }
    }
    
}
