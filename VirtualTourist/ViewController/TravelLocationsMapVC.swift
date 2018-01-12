//
//  TravelLocationsMapVC.swift
//  VirtualTourist
//
//  Created by Cong Doan on 1/11/18.
//  Copyright © 2018 Cong Doan. All rights reserved.
//

import UIKit
import MapKit

// MARK: - TravelLocationsMapVC: UIViewController

class TravelLocationsMapVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let touchAndHoldGesture = UILongPressGestureRecognizer(target: self, action: #selector(addPinAtLongPressPointOnMap))
        mapView.addGestureRecognizer(touchAndHoldGesture)
    }
    
    @objc func addPinAtLongPressPointOnMap(sender: UILongPressGestureRecognizer) {
        if sender.state != UIGestureRecognizerState.began {
            return
        }
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let pin = MKPointAnnotation()
        pin.coordinate = touchCoordinate
        mapView.addAnnotation(pin)
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
        navigationController!.pushViewController(photoAlbumVC, animated: true)
    }
    
}
