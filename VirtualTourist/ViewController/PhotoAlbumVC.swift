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
    var imageUrlsFetched: [String]!
    let albumSize = 24, pageSize = 4 * 24
    var albumNumberInPage = 1, pageNumber = 1
    var totalOfPages: Int!

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewSpinner: UIActivityIndicatorView!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUIBasedOnOrientation()
        
        let pinCoordinate = pinView.annotation!.coordinate
        FlickrClient.shared.imageUrlsAroundCoordinate(pinCoordinate, pageNumber: pageNumber, pageSize: pageSize) { (imageUrls, totalOfPages, error) in
            if let imageUrlsFetched = imageUrls as? [String] {
                self.imageUrlsFetched = imageUrlsFetched
                self.totalOfPages = totalOfPages
                print("totalOfPages: \(totalOfPages!)")
                let from = (self.albumNumberInPage - 1) * self.albumSize, to = min(from + self.albumSize, imageUrlsFetched.count)
                print("from/to/imageUrlsFetched.count: \(from)/\(to)/\(imageUrlsFetched.count)")
                self.imageUrls = Array(imageUrlsFetched[from..<to])
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
        
        configureUIBasedOnOrientation()
    }
    
    @IBAction func nextAlbumOfPhotos(_ sender: Any) {
        if albumNumberInPage * albumSize >= imageUrlsFetched.count && pageNumber >= totalOfPages {
            let alert = UIAlertController(title: nil, message: "There is No more images.", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default) { (_) in
                alert.dismiss(animated: true, completion: nil)
            }
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
            return
        }
        
        albumNumberInPage += 1
        let from = (albumNumberInPage - 1) * albumSize, to = min(from + albumSize, imageUrlsFetched.count)
        print("from/to/imageUrlsFetched.count: \(from)/\(to)/\(imageUrlsFetched.count)")
        imageUrls = Array(imageUrlsFetched[from..<to])
        collectionView.reloadData()
        
        /* Pre-fetch next page */
        if to == imageUrlsFetched.count && pageNumber < totalOfPages {
            albumNumberInPage = 0
            pageNumber += 1
            let pinCoordinate = pinView.annotation!.coordinate
            FlickrClient.shared.imageUrlsAroundCoordinate(pinCoordinate, pageNumber: pageNumber, pageSize: pageSize) { (imageUrls, totalOfPages, error) in
                if let imageUrls = imageUrls as? [String] {
                    self.imageUrlsFetched = imageUrls
                    self.totalOfPages = totalOfPages
                    print("totalOfPages: \(totalOfPages!)")
                    return
                }
                
                //TODO display error
            }
        }
    }
    
    private func configureUIBasedOnOrientation() {
        let isPortrait = UIDevice.current.orientation.isPortrait
        setViewHeightsBasedOnOrientation(isPortrait)
        populateImageViewBasedOnOrientation(isPortrait)
        setFlowLayoutPropertiesBasedOnOrientation(isPortrait)
    }
    
    private func setViewHeightsBasedOnOrientation(_ isPortrait: Bool) {
        if isPortrait {
            imageViewHeight.constant = 150
            newCollectionButtonHeight.constant = 44
        } else {
            imageViewHeight.constant = 100
            newCollectionButtonHeight.constant = 38
        }
    }
    
    private func populateImageViewBasedOnOrientation(_ isPortrait: Bool) {
        imageViewSpinner.startAnimating()
        
        let options = MKMapSnapshotOptions()
        let pinCoordinate = pinView.annotation!.coordinate
        let distanceInMeters: CLLocationDistance = isPortrait ? 6000 : 10000
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
    
    private func setFlowLayoutPropertiesBasedOnOrientation(_ isPortrait: Bool) {
        let numItemsInRow: CGFloat = isPortrait ? 3 : 4
        let spacing: CGFloat = 3.0
        let safeAreaWidth = UIApplication.shared.keyWindow!.safeAreaLayoutGuide.layoutFrame.width - 2.0 //since margin of colection view is 1 for each side
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
        cell.alpha = 0.5
        cell.imageView.image = nil
        cell.layer.cornerRadius = 10
        DispatchQueue.global(qos: .userInteractive).async {
            let data = try? Data(contentsOf: url)
            DispatchQueue.main.async {
                cell.spinner.stopAnimating()
                cell.alpha = 1.0
                cell.layer.cornerRadius = 0
                if let data = data {
                    cell.imageView.image = UIImage(data: data)
                }
            }
        }
    }
    
}
