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
    var annotationToResultOfFirstPageDownloadDict = [MKPointAnnotation : (imageUrls: [String]?, totalOfPages: Int?, error: Error?)]()
    var annotationToFirstPageDownloadObserverDict = [MKPointAnnotation : WeakRefFirstPageDownloadObserver]()

    @IBOutlet weak var mapView: MKMapView!


    override func viewDidLoad() {
        super.viewDidLoad()

        let touchAndHoldGesture = UILongPressGestureRecognizer(target: self, action: #selector(addPinAtLongPressPointOnMap))
        mapView.addGestureRecognizer(touchAndHoldGesture)
        
        loadSavedPins()
    }
    
    func loadSavedPins() {
        annotationToPinDict = [MKPointAnnotation : Pin]()
        coreDataStack.fetchPinsAsync { (pins) in
            guard pins.count > 0 else { return }
            var annotations = [MKAnnotation]()
            for pin in pins {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                annotations.append(annotation)
                self.annotationToPinDict[annotation] = pin
            }
            DispatchQueue.main.async {
                self.mapView.addAnnotations(annotations)
            }
        }
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
        let persistingContext = coreDataStack.persistingContext
        let pin = Pin(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude, context: persistingContext)
        annotationToPinDict[annotation] = pin
        
        // Start downloading the images immediately without waiting for the user to navigate to the collection view.
        downloadFirstPageOfImageUrlsForAnnotation(annotation)
    }

    private func downloadFirstPageOfImageUrlsForAnnotation(_ annotation: MKPointAnnotation) {
        FlickrClient.shared.imageUrlsAroundCoordinate(annotation.coordinate) { [weak self] (imageUrls, totalOfPages, error) in
            if let observer = self?.annotationToFirstPageDownloadObserverDict[annotation] {
                observer.value?.resultOfFirstPageDownload(imageUrls: imageUrls as! [String]?, totalOfPages: totalOfPages, error: error)
                self?.removeFirstPageDownloadObserver(forAnnotation: annotation)
            } else {
                self?.annotationToResultOfFirstPageDownloadDict[annotation] = (imageUrls as! [String]?, totalOfPages, error)
            }
        }
    }
    
    private func addFirstPageDownloadObserver(_ observer: WeakRefFirstPageDownloadObserver, forAnnotation annotation: MKPointAnnotation) {
        annotationToFirstPageDownloadObserverDict[annotation] = observer
    }
    
    private func removeFirstPageDownloadObserver(forAnnotation annotation: MKPointAnnotation) {
        annotationToFirstPageDownloadObserverDict.removeValue(forKey: annotation)
    }
    
}


protocol FirstPageDownloadObserver: NSObjectProtocol {
    
    func resultOfFirstPageDownload(imageUrls: [String]?, totalOfPages: Int?, error: Error?)
    
}

class WeakRefFirstPageDownloadObserver {
    
    private(set) weak var value: FirstPageDownloadObserver?
    
    init(value: FirstPageDownloadObserver?) {
        self.value = value
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
        let annotation = view.annotation as! MKPointAnnotation
        photoAlbumVC.pin = annotationToPinDict[annotation]
        if let downloadResult = annotationToResultOfFirstPageDownloadDict.removeValue(forKey: annotation) {
            if let error = downloadResult.error {
                // Handle the Download Error
                print("Error Downloading First Page of Image URLs: \(error)")
            } else {
                photoAlbumVC.storeDownloadResult(imageUrls: downloadResult.imageUrls!, totalOfPages: downloadResult.totalOfPages!)
            }
        } else {
            let weakRefPhotoAlbumVC = WeakRefFirstPageDownloadObserver(value: photoAlbumVC)
            addFirstPageDownloadObserver(weakRefPhotoAlbumVC, forAnnotation: annotation)
        }
        navigationController!.pushViewController(photoAlbumVC, animated: true)
    }
    
}
