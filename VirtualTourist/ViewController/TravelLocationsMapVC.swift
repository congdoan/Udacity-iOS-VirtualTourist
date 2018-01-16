//
//  TravelLocationsMapVC.swift
//  VirtualTourist
//
//  Created by Cong Doan on 1/11/18.
//  Copyright © 2018 Cong Doan. All rights reserved.
//

import UIKit
import MapKit
import CoreData

// MARK: - TravelLocationsMapVC: UIViewController

class TravelLocationsMapVC: UIViewController {
    
    var annotationToPinDict: [MKPointAnnotation : Pin]!

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let touchAndHoldGesture = UILongPressGestureRecognizer(target: self, action: #selector(addPinAtLongPressPointOnMap))
        mapView.addGestureRecognizer(touchAndHoldGesture)
        
        loadSavedPins()
    }
    
    @objc func addPinAtLongPressPointOnMap(sender: UILongPressGestureRecognizer) {
        if sender.state != UIGestureRecognizerState.began {
            return
        }
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchCoordinate
        mapView.addAnnotation(annotation)
        let mainContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.context
        let pin = Pin(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude, context: mainContext)
        annotationToPinDict[annotation] = pin
    }

}

extension TravelLocationsMapVC {
    
    func loadSavedPins() {
        annotationToPinDict = [MKPointAnnotation : Pin]()
        let fetchRequest = Pin.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor]()
        let mainContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.context
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: mainContext,
                                                                  sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
            if let pins = fetchedResultsController.fetchedObjects as? [Pin] {
                mapView.removeAnnotations(mapView.annotations)
                for pin in pins {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                    annotationToPinDict[annotation] = pin
                    mapView.addAnnotation(annotation)
                }
            }
        } catch {
            fatalError("Error fetching Pin objects: \(error)")
        }
    }
    
}

// MARK: - TravelLocationsMapVC: MKMapViewDelegate

extension TravelLocationsMapVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let photoAlbumVC = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumVC") as! PhotoAlbumVC
        photoAlbumVC.pinView = view
        photoAlbumVC.pin = annotationToPinDict[view.annotation as! MKPointAnnotation]
        navigationController!.pushViewController(photoAlbumVC, animated: true)
    }
    
}
