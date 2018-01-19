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
    var annotationToFirstPageDownloadResultDict = [MKPointAnnotation : PageDownloadResult]()
    var annotationsDownloadInProgress = Set<MKPointAnnotation>()
    var annotationToFirstPageDownloadObserverDict = [MKPointAnnotation : WeakRefFirstPageDownloadObserver]()

    @IBOutlet weak var mapView: MKMapView!


    override func viewDidLoad() {
        super.viewDidLoad()

        let touchAndHoldGesture = UILongPressGestureRecognizer(target: self, action: #selector(addPinAtLongPressPointOnMap))
        mapView.addGestureRecognizer(touchAndHoldGesture)
        
        loadSavedPins()
        
        restoreMapRegion()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Persist the center & zoom level of the map (i.e. the current region of the map)
        saveMapRegion()
    }
    
    private func saveMapRegion() {
        let region = mapView.region
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "region")
        userDefaults.set(region.center.latitude, forKey: "region.center.latitude")
        userDefaults.set(region.center.longitude, forKey: "region.center.longitude")
        userDefaults.set(region.span.latitudeDelta, forKey: "region.span.latitudeDelta")
        userDefaults.set(region.span.longitudeDelta, forKey: "region.span.longitudeDelta")
    }
    
    private func restoreMapRegion() {
        let userDefaults = UserDefaults.standard
        if userDefaults.bool(forKey: "region") {
            let latitude = userDefaults.double(forKey: "region.center.latitude")
            let longitude = userDefaults.double(forKey: "region.center.longitude")
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let latitudeDelta = userDefaults.double(forKey: "region.span.latitudeDelta")
            let longitudeDelta = userDefaults.double(forKey: "region.span.longitudeDelta")
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            let region = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(region, animated: true)
        }
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
        let coreDataStack = self.coreDataStack
        let pin = Pin(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude, context: coreDataStack.persistingContext)
        coreDataStack.saveAsync()
        annotationToPinDict[annotation] = pin
        
        // Start downloading the images immediately without waiting for the user to navigate to the collection view.
        annotationsDownloadInProgress.insert(annotation)
        downloadFirstPageOfImageUrlsForAnnotation(annotation)
    }

    private func downloadFirstPageOfImageUrlsForAnnotation(_ annotation: MKPointAnnotation) {
        FlickrClient.shared.imageUrlsAroundCoordinate(annotation.coordinate) { [weak self] (imageUrls, totalOfPages, error) in
            if let observer = self?.annotationToFirstPageDownloadObserverDict[annotation] {
                observer.value?.notifyObserverOfDownloadResult( (imageUrls as! [String]?, totalOfPages, error) )
                self?.removeFirstPageDownloadObserver(forAnnotation: annotation)
            } else {
                self?.annotationToFirstPageDownloadResultDict[annotation] = (imageUrls as! [String]?, totalOfPages, error)
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
    
    func notifyObserverOfDownloadResult(_ result: PageDownloadResult)
    
}

class WeakRefFirstPageDownloadObserver {
    
    private(set) weak var value: FirstPageDownloadObserver?
    
    init(value: FirstPageDownloadObserver?) {
        self.value = value
    }
    
}

typealias PageDownloadResult = (imageUrls: [String]?, totalOfPages: Int?, error: Error?)


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
        let pin = annotationToPinDict[annotation]!
        let pinPhotos = Array(pin.photos!) as! [Photo]
        photoAlbumVC.pin = pin
        photoAlbumVC.pinPhotos = pinPhotos
        if pinPhotos.count == 0 {
            if let downloadResult = annotationToFirstPageDownloadResultDict.removeValue(forKey: annotation) {
                photoAlbumVC.pageDownloadResult = downloadResult
            } else if annotationsDownloadInProgress.contains(annotation) {
                // Download of first page is In Progress
                let weakRefPhotoAlbumVC = WeakRefFirstPageDownloadObserver(value: photoAlbumVC)
                addFirstPageDownloadObserver(weakRefPhotoAlbumVC, forAnnotation: annotation)
                annotationsDownloadInProgress.remove(annotation)
            } else {
                downloadFirstPageOfImageUrlsForAnnotation(annotation)
                let weakRefPhotoAlbumVC = WeakRefFirstPageDownloadObserver(value: photoAlbumVC)
                addFirstPageDownloadObserver(weakRefPhotoAlbumVC, forAnnotation: annotation)
            }
        }
        navigationController!.pushViewController(photoAlbumVC, animated: true)
    }
    
}
