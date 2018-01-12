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

        populateImageView(UIScreen.main.bounds.width < UIScreen.main.bounds.height, UIScreen.main.bounds.width)
    }
    
    private func populateImageView(_ portrait: Bool, _ width: CGFloat) {
        print("++++++")
        print("UIScreen.main.bounds.size: \(UIScreen.main.bounds.size)")
        print("imageView.bounds.size: \(imageView.bounds.size)")
        print("albumView.bounds.size: \(albumView.bounds.size)")

        /* Capture a portion around the pin */
        let options = MKMapSnapshotOptions()
        let coordinate = pinView.annotation!.coordinate
        let distanceInMeters: CLLocationDistance = portrait ? 6000 : 10000
        let region = MKCoordinateRegionMakeWithDistance(coordinate, distanceInMeters, distanceInMeters)
        options.region = region
        options.size = CGSize(width: width, height: imageView.bounds.height)
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
    
//    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
//        populateImageView(fromInterfaceOrientation.isLandscape)
//    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        populateImageView(size.width < size.height, size.width)
    }

}
