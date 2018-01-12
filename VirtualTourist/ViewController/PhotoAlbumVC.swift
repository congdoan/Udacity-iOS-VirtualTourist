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

        let screenBound = UIScreen.main.bounds
        populateImageView(isPortrait: screenBound.width < screenBound.height, screenwidth: screenBound.width)
    }
    
    private func populateImageView(isPortrait: Bool, screenwidth: CGFloat) {
        let options = MKMapSnapshotOptions()
        let pinCoordinate = pinView.annotation!.coordinate
        let distanceInMeters: CLLocationDistance = isPortrait ? 6000 : 10000
        let pinCenteredRegion = MKCoordinateRegionMakeWithDistance(pinCoordinate, distanceInMeters, distanceInMeters)
        options.region = pinCenteredRegion
        options.size = CGSize(width: screenwidth, height: imageView.bounds.height)
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { (snapshot, error) in
            guard let snapshot = snapshot, error == nil else {
                print("ERROR Snapshotting MapView: \(error!)")
                return
            }
            
            UIGraphicsBeginImageContext(options.size)
            snapshot.image.draw(at: .zero) // snapshot's image
            
            /* Draw pin image at the center of the region */
            var point = snapshot.point(for: pinCoordinate)
            let pinSize = self.pinView.bounds.size
            point.x -= pinSize.width / 2
            point.y -= pinSize.height / 2
            let pinCenterOffset = self.pinView.centerOffset
            point.x += pinCenterOffset.x
            point.y += pinCenterOffset.y
            self.pinView.image!.draw(at: point) // pin image
            
            let imageOfSnapshotAndPin = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            DispatchQueue.main.async {
                self.imageView.image = imageOfSnapshotAndPin
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        populateImageView(isPortrait: size.width < size.height, screenwidth: size.width)
    }

}
