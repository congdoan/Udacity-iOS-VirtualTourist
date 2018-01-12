//
//  PhotoAlbumVC.swift
//  VirtualTourist
//
//  Created by Cong Doan on 1/11/18.
//  Copyright © 2018 Cong Doan. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumVC: UIViewController {
    
    var pinView: MKAnnotationView!

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var albumView: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        populateImageView(UIScreen.main.bounds.width < UIScreen.main.bounds.height)
    }
    
    private func populateImageView(_ portrait: Bool) {
        let size = UIScreen.main.bounds
        print("++++++")
        print("UIScreen size: \(size.width), \(size.height)")
        print("imageView.bounds: \(imageView.bounds.width), \(imageView.bounds.height)")
        print("albumView.bounds: \(albumView.bounds.width), \(albumView.bounds.height)")

        /* Capture a portion around the pin */
        let options = MKMapSnapshotOptions()
        let coordinate = pinView.annotation!.coordinate
        //let longitudeDistance: CLLocationDistance = 3500
        //let width = CLLocationDistance(imageView.bounds.width), height = CLLocationDistance(imageView.bounds.height)
        //let latitudeDistance: CLLocationDistance = (longitudeDistance * width) / height
        //print("latitudeDistance/longitudeDistance: \(latitudeDistance)/\(longitudeDistance)")
        //let region = MKCoordinateRegionMakeWithDistance(coordinate, latitudeDistance, longitudeDistance)
        let distanceInMeters: CLLocationDistance = portrait ? 6000 : 10000
        let region = MKCoordinateRegionMakeWithDistance(coordinate, distanceInMeters, distanceInMeters)
        options.region = region
        //options.mapRect = mapRectForCoordinateRegion(region)
        print("options.mapRect.size: \(options.mapRect.size)")
        options.size = imageView.bounds.size
        print("imageView.bounds.size: \(imageView.bounds.size)")
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { (snapshot, error) in
            guard let snapshot = snapshot, error == nil else {
                print("ERROR Snapshotting MapView: \(error!)")
                return
            }
            
            print("snapshot.image.size: \(snapshot.image.size)")
            print("------")

            DispatchQueue.main.async {
                self.imageView.image = snapshot.image
            }
        }
    }
    
    func mapRectForCoordinateRegion(_ region:MKCoordinateRegion) -> MKMapRect {
        let topLeft = CLLocationCoordinate2D(latitude: region.center.latitude + (region.span.latitudeDelta/2),
                                             longitude: region.center.longitude - (region.span.longitudeDelta/2))
        let bottomRight = CLLocationCoordinate2D(latitude: region.center.latitude - (region.span.latitudeDelta/2),
                                                 longitude: region.center.longitude + (region.span.longitudeDelta/2))
        
        let a = MKMapPointForCoordinate(topLeft)
        let b = MKMapPointForCoordinate(bottomRight)
        
        return MKMapRect(origin: MKMapPoint(x:min(a.x,b.x), y:min(a.y,b.y)),
                         size: MKMapSize(width: abs(a.x-b.x), height: abs(a.y-b.y)))
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        populateImageView(fromInterfaceOrientation.isLandscape)
    }

    /*
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        print("Size: \(size)")
        populateImageView(size.width < size.height)
    }
    */

}
