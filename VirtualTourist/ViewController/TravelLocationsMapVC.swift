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
        //reason: Illegal attempt to establish a relationship 'pin' between objects in different contexts.
        let backgroundContext = coreDataStack.backgroundContext
        let pin = Pin(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude, context: backgroundContext)
        annotationToPinDict[annotation] = pin
    }

}

extension TravelLocationsMapVC {
    
    func loadSavedPins() {
        annotationToPinDict = [MKPointAnnotation : Pin]()
        /*
         var annotations = [MKAnnotation]()
         let pins = coreDataStack.fetchPins()
         for pin in pins {
         let annotation = MKPointAnnotation()
         annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
         annotations.append(annotation)
         annotationToPinDict[annotation] = pin
         }
         mapView.addAnnotations(annotations)
        */
        //coreDataStack.fetchPinsAsync { (pins) in
        coreDataStack.fetchPinsAsync2 { (pins) in
            guard pins.count > 0 else { return }
            var annotations = [MKAnnotation]()
            for pin in pins {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                annotations.append(annotation)
                self.annotationToPinDict[annotation] = pin
            }
            DispatchQueue.main.async {
                print("coreDataStack.fetchPinsAsync2 RETURNED at \(Date())")
                self.mapView.addAnnotations(annotations)
            }
        }
        print("loadSavedPins RETURNED                 at \(Date())")
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
