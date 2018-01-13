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
    var itemSizePortrait: CGSize!
    var itemSizeLandscape: CGSize!
    var isPortrait: Bool!

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewSpinner: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setFlowLayoutProperties()

        populateImageView(safeAreaWidth: UIApplication.shared.keyWindow!.safeAreaLayoutGuide.layoutFrame.width)
        
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
    
    /*
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        isPortrait = !isPortrait
        flowLayout.itemSize = isPortrait ? itemSizePortrait : itemSizeLandscape
        flowLayout.invalidateLayout()
        
        populateImageView(safeAreaWidth: UIApplication.shared.keyWindow!.safeAreaLayoutGuide.layoutFrame.height)
    }
    */
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotate(from: fromInterfaceOrientation)
        
        isPortrait = !isPortrait
        flowLayout.itemSize = isPortrait ? itemSizePortrait : itemSizeLandscape
        flowLayout.invalidateLayout()
        
        populateImageView(safeAreaWidth: UIApplication.shared.keyWindow!.safeAreaLayoutGuide.layoutFrame.width)
    }

    private func populateImageView(safeAreaWidth: CGFloat) {
        imageViewSpinner.startAnimating()
        
        let options = MKMapSnapshotOptions()
        let pinCoordinate = pinView.annotation!.coordinate
        let distanceInMeters: CLLocationDistance = isPortrait ? 6000 : 10000
        let pinCenteredRegion = MKCoordinateRegionMakeWithDistance(pinCoordinate, distanceInMeters, distanceInMeters)
        options.region = pinCenteredRegion
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
        print("+++setFlowLayoutProperties+++")
        isPortrait = UIDevice.current.orientation.isPortrait
        //let safeAreaFrame = UIApplication.shared.keyWindow!.frame
        let safeAreaFrame = UIApplication.shared.keyWindow!.safeAreaLayoutGuide.layoutFrame
        let safeAreaWidth = safeAreaFrame.width, safeAreaHeight = safeAreaFrame.height
        let safeAreaMinDimen = min(safeAreaWidth, safeAreaHeight), safeAreaMaxDimen = max(safeAreaWidth, safeAreaHeight)
        let numItemsInRowPortrait: CGFloat = 3, numItemsInRowLandscape: CGFloat = 5
        let spacing: CGFloat = 3.0
        let dimensionPortrait = (safeAreaMinDimen - (numItemsInRowPortrait *  spacing) + spacing) / numItemsInRowPortrait
        let dimensionLandscape = (safeAreaMaxDimen - (numItemsInRowLandscape *  spacing) + spacing) / numItemsInRowLandscape - 2.4
        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.minimumLineSpacing = spacing
        itemSizePortrait = CGSize(width: dimensionPortrait, height: dimensionPortrait)
        itemSizeLandscape = CGSize(width: dimensionLandscape, height: dimensionLandscape)
        flowLayout.itemSize = isPortrait ? itemSizePortrait : itemSizeLandscape
        print("setFlowLayoutProperties isPortrait       : \(isPortrait!)")
        print("setFlowLayoutProperties totalAreaSize    : \(UIApplication.shared.keyWindow!.frame.size)")
        print("setFlowLayoutProperties safeAreaSize     : \(safeAreaFrame.size)")
        print("setFlowLayoutProperties safeAreaInsets   : \(UIApplication.shared.keyWindow!.safeAreaInsets)")
        print("setFlowLayoutProperties itemSizePortrait : \(itemSizePortrait!)")
        print("setFlowLayoutProperties itemSizeLandscape: \(itemSizeLandscape!)")
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
    
    private func iPhoneX() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .phone && UIScreen.main.nativeBounds.height == 2436
    }
    
}
