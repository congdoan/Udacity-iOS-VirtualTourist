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

        populateImageView(isPortrait: UIDevice.current.orientation.isPortrait, screenWidth: UIScreen.main.bounds.width)
        
        let pinCoordinate = pinView.annotation!.coordinate
        FlickrClient.shared.imageUrlsAroundCoordinate(pinCoordinate) { (imageUrls, error) in
            if let imageUrls = imageUrls as? [String] {
                self.imageUrls = imageUrls
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                return
            }
            
            //TODO display error
        }
        
        setFlowLayoutProperties(safeAreaWidth: UIApplication.shared.keyWindow!.safeAreaLayoutGuide.layoutFrame.width)
    }
    
    private func populateImageView(isPortrait: Bool, screenWidth: CGFloat) {
        imageViewSpinner.startAnimating()
        
        let options = MKMapSnapshotOptions()
        let pinCoordinate = pinView.annotation!.coordinate
        let distanceInMeters: CLLocationDistance = isPortrait ? 6000 : 10000
        let pinCenteredRegion = MKCoordinateRegionMakeWithDistance(pinCoordinate, distanceInMeters, distanceInMeters)
        options.region = pinCenteredRegion
        options.size = CGSize(width: screenWidth, height: imageView.bounds.height)
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        print("viewWillTransition UIDevice.isPortrait: \(UIDevice.current.orientation.isPortrait)")
        populateImageView(isPortrait: size.width < size.height,
                          screenWidth: UIApplication.shared.keyWindow!.safeAreaLayoutGuide.layoutFrame.height)
    }
    
    // MARK: Set the Collection View Flow Layout's Properties
    
    private func setFlowLayoutProperties(safeAreaWidth: CGFloat) {
        print("+++setFlowLayoutProperties+++")
        print("setFlowLayoutProperties safeAreaWidth: \(safeAreaWidth)")
        let spacing: CGFloat = 3
        let numberOfItemsInRow: CGFloat = UIDevice.current.orientation.isPortrait ? 3 : 5
        let numberOfSpacingsInRow: CGFloat = numberOfItemsInRow - 1
        let dimension = ((safeAreaWidth - (numberOfSpacingsInRow *  spacing)) / numberOfItemsInRow)
        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.minimumLineSpacing = spacing
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        print("setFlowLayoutProperties flowLayout.itemSize: \(flowLayout.itemSize)")
        print("---setFlowLayoutProperties---")
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
    
}
