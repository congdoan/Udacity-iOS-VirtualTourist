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
    
    var pinView: MKAnnotationView!, pin: Pin!, pinPhotos: [Photo]!
    var imageUrls = [String]()
    var imageUrlsFetched: [String]!
    let albumSize = 24, pageSize = 4 * 24
    var albumNumberInPage = 1, pageNumber = 1
    var totalOfPages: Int!
    var selectedItems: [Bool]!
    var fetchedImages: [UIImage?]!
    var selectedItemCount = 0

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewSpinner: UIActivityIndicatorView!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var buttonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUIBasedOnOrientation()
        
        loadPinPhotos()
    }
    
    private func loadPinPhotos() {
        if let photos = pin.photos, photos.count > 0 {
            pinPhotos = Array(photos)
            selectedItems = Array(repeating: false, count: pinPhotos.count)
            collectionView.reloadData()
            return
        }
        
        downloadPhotosForPinFromFlickr()
    }
    
    private func downloadPhotosForPinFromFlickr() {
        let pinCoordinate = pinView.annotation!.coordinate
        FlickrClient.shared.imageUrlsAroundCoordinate(pinCoordinate, pageNumber: pageNumber, pageSize: pageSize) { (imageUrls, totalOfPages, error) in
            if let imageUrlsFetched = imageUrls as? [String] {
                self.imageUrlsFetched = imageUrlsFetched
                self.totalOfPages = totalOfPages
                print("totalOfPages: \(totalOfPages!)")
                let from = (self.albumNumberInPage - 1) * self.albumSize, to = min(from + self.albumSize, imageUrlsFetched.count)
                print("from/to/imageUrlsFetched.count: \(from)/\(to)/\(imageUrlsFetched.count)")
                self.imageUrls = Array(imageUrlsFetched[from..<to])
                self.selectedItems = Array(repeating: false, count: to - from)
                self.fetchedImages = Array(repeating: nil, count: to - from)
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                return
            }
            
            //TODO display error
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        guard let fetchedImages = fetchedImages else {
            return
        }
        
        /* Save the Pin and its Photos via Core Data */
        let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
        for uiImage in fetchedImages {
            if let uiImage = uiImage {
                let data = UIImagePNGRepresentation(uiImage)!
                let _ = Photo(data: data, pin: pin, context: coreDataStack.context)
            }
        }
        coreDataStack.save()
        print("coreDataStack.save() DONE!")
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        //super.didRotate(from: fromInterfaceOrientation)
        
        configureUIBasedOnOrientation()
    }
    
    @IBAction func buttonPressed(_ sender: Any) {
        if selectedItemCount == 0 {
            displayNextAlbumOfPhotos()
        } else {
            removeSelectedPhotos()
        }
    }
    
    private func displayNextAlbumOfPhotos() {
        guard let imageUrlsFetched = imageUrlsFetched else {
            downloadPhotosForPinFromFlickr()
            return
        }
        
        if albumNumberInPage * albumSize >= imageUrlsFetched.count && pageNumber >= totalOfPages {
            showAlert()
            return
        }
        
        albumNumberInPage += 1
        let from = (albumNumberInPage - 1) * albumSize, to = min(from + albumSize, imageUrlsFetched.count)
        print("from/to/imageUrlsFetched.count: \(from)/\(to)/\(imageUrlsFetched.count)")
        imageUrls = Array(imageUrlsFetched[from..<to])
        selectedItems = Array(repeating: false, count: to - from)
        fetchedImages = Array(repeating: nil, count: to - from)
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
    
    private func removeSelectedPhotos() {
        var newImageUrls = [String]()
        for i in 0..<selectedItems.count {
            if !selectedItems[i] {
                newImageUrls.append(imageUrls[i])
            }
        }
        imageUrls = newImageUrls
        collectionView.reloadData()
        selectedItems = Array(repeating: false, count: imageUrls.count)
        selectedItemCount = 0
        button.setTitle("New Collection", for: .normal)
    }
    
    private func showAlert() {
        let alert = UIAlertController(title: nil, message: "There is No more images.", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { (_) in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
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
            buttonHeightConstraint.constant = 44
        } else {
            imageViewHeight.constant = 100
            buttonHeightConstraint.constant = 38
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
        if let photos = pinPhotos {
            return photos.count
        } else {
            return imageUrls.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCell", for: indexPath) as! PhotoAlbumCell
        
        if let photos = pinPhotos {
            cell.imageView.image = UIImage(data: photos[indexPath.item].data)
            cell.alpha = selectedItems[indexPath.item] ? 0.3 : 1.0
            return cell
        }
        
        if let image = fetchedImages[indexPath.item] {
            cell.imageView.image = image
            cell.alpha = selectedItems[indexPath.item] ? 0.3 : 1.0
        } else {
            /* Fetch the image & Populate the cell */
            let url = URL(string: imageUrls[indexPath.item])!
            cell.spinner.startAnimating()
            cell.alpha = selectedItems[indexPath.item] ? 0.3 : 0.5
            cell.imageView.image = nil
            cell.layer.cornerRadius = 10
            DispatchQueue.global(qos: .userInteractive).async {
                let data = try? Data(contentsOf: url)
                if let data = data {
                    self.fetchedImages[indexPath.item] = UIImage(data: data)
                }
                DispatchQueue.main.async {
                    cell.spinner.stopAnimating()
                    cell.alpha = self.selectedItems[indexPath.item] ? 0.3 : 1.0
                    cell.layer.cornerRadius = 0
                    if let image = self.fetchedImages[indexPath.item] {
                        cell.imageView.image = image
                    }
                }
            }
        }

        return cell
    }
    
}

extension PhotoAlbumVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard fetchedImages[indexPath.item] != nil else {
            return
        }
        selectedItems[indexPath.item] = !selectedItems[indexPath.item]
        if selectedItems[indexPath.item] {
            collectionView.cellForItem(at: indexPath)!.alpha = 0.3
            selectedItemCount += 1
        } else {
            collectionView.cellForItem(at: indexPath)!.alpha = 1.0
            selectedItemCount -= 1
        }
        button.setTitle(selectedItemCount > 0 ? "Remove Selected Photos" : "New Collection", for: .normal)
    }
    
}

