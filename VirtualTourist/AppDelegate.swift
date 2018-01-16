//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Cong Doan on 1/11/18.
//  Copyright © 2018 Cong Doan. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let coreDataStack = CoreDataStack(modelName: "Model")!


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // TEST: Load & Print All the Existing Pin and Photo objects
        var fetchRequest = Pin.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        var fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: coreDataStack.context,
                                                                  sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
            if let pins = fetchedResultsController.fetchedObjects as? [Pin] {
                print("++++++++Pins in Core Data++++++++")
                var i = 1
                for pin in pins {
                    print("Pin \(i): latitude=\(pin.latitude), longitude=\(pin.longitude)")
                    i += 1
                }
                print("--------Pins in Core Data--------")
            }
        } catch {
            fatalError("Error fetching Pin objects: \(error)")
        }
        
        fetchRequest = Photo.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor]()
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: coreDataStack.context,
                                                              sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
            if let photos = fetchedResultsController.fetchedObjects as? [Photo] {
                print("++++++++Photos in Core Data++++++++")
                var i = 1
                for photo in photos {
                    print("Photo \(i): \(photo.data!.count) bytes")
                    i += 1
                }
                print("--------Photos in Core Data--------")
            }
        } catch {
            fatalError("Error fetching Photo objects: \(error)")
        }
        

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

