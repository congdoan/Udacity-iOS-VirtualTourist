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
        print("++++++")
        print("imageView.bounds.size: \(imageView.bounds.size)")
        print("albumView.bounds.size: \(albumView.bounds.size)")

        /* Capture a portion around the pin */
        let options = MKMapSnapshotOptions()
        let coordinate = pinView.annotation!.coordinate
        let distanceInMeters: CLLocationDistance = portrait ? 6000 : 10000
        let region = MKCoordinateRegionMakeWithDistance(coordinate, distanceInMeters, distanceInMeters)
        options.region = region
        options.size = imageView.bounds.size
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { (snapshot, error) in
            guard let snapshot = snapshot, error == nil else {
                print("ERROR Snapshotting MapView: \(error!)")
                return
            }
            
            print("snapshot.image.size  : \(snapshot.image.size)")
            print("------")
            
            
            UIGraphicsBeginImageContext(options.size)
            
            snapshot.image.draw(at: .zero)
            
            var point = snapshot.point(for: coordinate)
            let pinSize = self.pinView.bounds.size
            point.x -= pinSize.width / 2
            point.y -= pinSize.height / 2
            let pinCenterOffset = self.pinView.centerOffset
            point.x += pinCenterOffset.x
            point.y += pinCenterOffset.y
            let pinImage = self.pinView.image!
            pinImage.draw(at: point)
            
            let image = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()

            
            DispatchQueue.main.async {
                self.imageView.image = image
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
