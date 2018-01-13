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
    var imageUrls = [String]()

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewSpinner: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setFlowLayoutProperties()

        populateImageView()
        
        let pinCoordinate = pinView.annotation!.coordinate
        FlickrClient.shared.imageUrlsAroundCoordinate(pinCoordinate) { (imageUrls, error) in
            if let imageUrls = imageUrls as? [String] {
                self.imageUrls = Array(imageUrls.prefix(24))
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                return
            }
            
            //TODO display error
        }
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        //super.didRotate(from: fromInterfaceOrientation)
        
        setFlowLayoutProperties()
        flowLayout.invalidateLayout()
        
        populateImageView()
    }

    private func populateImageView() {
        imageViewSpinner.startAnimating()
        
        let options = MKMapSnapshotOptions()
        let pinCoordinate = pinView.annotation!.coordinate
        let distanceInMeters: CLLocationDistance = UIDevice.current.orientation.isPortrait ? 6000 : 10000
        let pinCenteredRegion = MKCoordinateRegionMakeWithDistance(pinCoordinate, distanceInMeters, distanceInMeters)
        options.region = pinCenteredRegion
        let safeAreaWidth = UIApplication.shared.keyWindow!.safeAreaLayoutGuide.layoutFrame.width
        options.size = CGSize(width: safeAreaWidth, height: imageView.bounds.height)
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { (snapshot, error) in
            guard let snapshot = snapshot, error == nil else {
                print("ERROR Snapshotting MapView: \(error!)")
                
                DispatchQueue.main.async {
                    self.imageViewSpinner.stopAnimating()
                }
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
                self.imageViewSpinner.stopAnimating()
                self.imageView.image = imageOfSnapshotAndPin
            }
        }
    }
    
    // MARK: Set the Collection View Flow Layout's Properties
    
    private func setFlowLayoutProperties() {
        let numItemsInRow: CGFloat = UIDevice.current.orientation.isPortrait ? 3 : 5
        let spacing: CGFloat = 3.0
        let safeAreaWidth = UIApplication.shared.keyWindow!.safeAreaLayoutGuide.layoutFrame.width
        let dimension = (safeAreaWidth - (numItemsInRow *  spacing) + spacing) / numItemsInRow
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.minimumLineSpacing = spacing
    }
    
}

extension PhotoAlbumVC: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCell", for: indexPath) as! PhotoAlbumCell
        
        // Configure the cell
        let url = URL(string: imageUrls[indexPath.row])!
        fetchImageFromUrlForCell(url, cell)
        
        return cell
    }
    
    private func fetchImageFromUrlForCell(_ url: URL, _ cell: PhotoAlbumCell) {
        cell.spinner.startAnimating()
        DispatchQueue.global(qos: .userInteractive).async {
            let data = try? Data(contentsOf: url)
            DispatchQueue.main.async {
                cell.spinner.stopAnimating()
                if let data = data {
                    cell.imageView.image = UIImage(data: data)
                }
            }
        }
    }
    
    private func iPhoneX() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .phone && UIScreen.main.nativeBounds.height == 2436
    }
    
}
