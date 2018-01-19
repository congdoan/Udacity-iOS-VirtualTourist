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
    
    var pin: Pin!
    var pinView: MKAnnotationView!
    var pinPhotos = [Photo]()
    var pageDownloadResult: PageDownloadResult!
    var imageUrlsOfAlbum = [String]()
    let albumSize = 24, pageSize = 4 * 24 // 1 page = 4 albums
    var albumNumberInPage = 1, pageNumber = 1
    var fetchedImagesOfAlbum: [UIImage?]!
    var selectedItems: [Bool]!
    var selectedItemCount = 0
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewSpinner: UIActivityIndicatorView!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewSpinner: UIActivityIndicatorView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var buttonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var pinHasNoImagesLabel: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUIBasedOnOrientation()
        
        if pinPhotos.count == 0 {
            if pageDownloadResult != nil {
                // Download of First Page Finished
                updateUIViews()
            } else {
                // Download of First Page In Progress
                updateUIBasedOnDownloadStatus(true)
            }
        } else {
            selectedItems = Array(repeating: false, count: pinPhotos.count)
        }
    }
    
    private func updateUIViews() {
        let fetchedImageUrlsOfPage = pageDownloadResult.imageUrls!
        if fetchedImageUrlsOfPage.count > 0 {
            let from = (self.albumNumberInPage - 1) * self.albumSize, to = min(from + self.albumSize, fetchedImageUrlsOfPage.count)
            print("updateUIViews() from/to/fetchedImageUrls: \(from)/\(to)/\(fetchedImageUrlsOfPage.count)")
            imageUrlsOfAlbum = Array(fetchedImageUrlsOfPage[from..<to])
            selectedItems = Array(repeating: false, count: to - from)
            fetchedImagesOfAlbum = Array(repeating: nil, count: to - from)
            collectionView.reloadData()
        } else {
            pinHasNoImagesLabel.isHidden = false
        }
    }
    
    private func downloadFirstPageOfImageUrls() {
        updateUIBasedOnDownloadStatus(true)

        let pinCoordinate = pinView.annotation!.coordinate
        FlickrClient.shared.imageUrlsAroundCoordinate(pinCoordinate,
                                                      pageNumber: pageNumber,
                                                      pageSize: pageSize) { [weak self] (imageUrls, totalOfPages, error) in
            
            if let downloadError = error {
                print("Error Downloading First Page of Image URLs: \(downloadError)")
            }

            DispatchQueue.main.async {
                if let this = self {
                    this.pageDownloadResult = (imageUrls as? [String], totalOfPages, error)
                    this.updateUIBasedOnDownloadStatus(false)
                    if error != nil {
                        this.showAlert(message: "Error while downloading images.")
                    } else {
                        let persistingContext = this.coreDataStack.persistingContext
                        for photo in this.pinPhotos {
                            persistingContext.delete(photo)
                        }
                        this.pinPhotos = [Photo]()
                        
                        this.updateUIViews()
                    }
                }
            }
        }
    }
    
    private func updateUIBasedOnDownloadStatus(_ downloading: Bool) {
        if downloading {
            collectionViewSpinner.startAnimating()
        } else {
            collectionViewSpinner.stopAnimating()
        }
        self.button.isEnabled = !downloading
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        if let fetchedImagesOfAlbum = fetchedImagesOfAlbum {
            /* Save the Pin and its Photos */
            coreDataStack.performBackgroundBatchOperation({ (persistingContext) in
                for uiImage in fetchedImagesOfAlbum {
                    if let uiImage = uiImage {
                        let data = UIImagePNGRepresentation(uiImage)!
                        let _ = Photo(data: data, pin: self.pin, context: persistingContext)
                    }
                }
            })
        }
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
        let fetchedImageUrls = pageDownloadResult.imageUrls!, totalOfPages = pageDownloadResult.totalOfPages!
        if albumNumberInPage * albumSize >= fetchedImageUrls.count && pageNumber >= totalOfPages {
            showAlert(message: "There is no more images for this pin.")
            return
        }
        
        albumNumberInPage += 1
        let from = (albumNumberInPage - 1) * albumSize, to = min(from + albumSize, fetchedImageUrls.count)
        print("from/to/fetchedImageUrls: \(from)/\(to)/\(fetchedImageUrls.count)")
        imageUrlsOfAlbum = Array(fetchedImageUrls[from..<to])
        selectedItems = Array(repeating: false, count: to - from)
        fetchedImagesOfAlbum = Array(repeating: nil, count: to - from)
        collectionView.reloadData()
        
        /* Pre-fetch Next Page of Image URLs */
        if to == fetchedImageUrls.count && pageNumber < totalOfPages {
            button.isEnabled = false
            
            albumNumberInPage = 0
            pageNumber += 1
            let pageNumberForDebuggingInCaseOfError = pageNumber
            let pinCoordinate = pinView.annotation!.coordinate
            FlickrClient.shared.imageUrlsAroundCoordinate(pinCoordinate,
                                                          pageNumber: pageNumber,
                                                          pageSize: pageSize) { [weak self] (imageUrls, totalOfPages, error) in
                
                if let downloadError = error {
                    print("Error Downloading \(pageNumberForDebuggingInCaseOfError)-th Page of Image URLs: \(downloadError)")
                }
                                                            
                DispatchQueue.main.async {
                    if let this = self {
                        this.pageDownloadResult = (imageUrls as? [String], totalOfPages, error)
                        this.button.isEnabled = true
                        if error == nil {
                            this.showAlert(message: "Error while downloading images.")
                        }
                    }
                }
            }
        }
    }
    
    private func removeSelectedPhotos() {
        if imageUrlsOfAlbum.count > 0 {
            var unselectedImageUrls = [String]()
            var unselectedImages = [UIImage?]()
            for i in 0..<selectedItems.count {
                if !selectedItems[i] {
                    unselectedImageUrls.append(imageUrlsOfAlbum[i])
                    unselectedImages.append(fetchedImagesOfAlbum[i])
                }
            }
            imageUrlsOfAlbum = unselectedImageUrls
            fetchedImagesOfAlbum = unselectedImages
            selectedItems = Array(repeating: false, count: imageUrlsOfAlbum.count)
        } else {
            let persistingContext = coreDataStack.persistingContext
            for i in 0..<selectedItems.count {
                if selectedItems[i] {
                    pin.removeFromPhotos(pinPhotos[i])
                    persistingContext.delete(pinPhotos[i])
                }
            }
            pinPhotos = Array(pin.photos!) as! [Photo]
            selectedItems = Array(repeating: false, count: pinPhotos.count)
        }
        collectionView.reloadData()
        selectedItemCount = 0
        button.setTitle("New Collection", for: .normal)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
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
        if imageUrlsOfAlbum.count > 0 {
            return imageUrlsOfAlbum.count
        } else {
            return pinPhotos.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCell", for: indexPath) as! PhotoAlbumCell
        
        if imageUrlsOfAlbum.count > 0 {
            if let image = fetchedImagesOfAlbum[indexPath.item] {
                cell.imageView.image = image
                cell.alpha = selectedItems[indexPath.item] ? 0.3 : 1.0
            } else {
                /* Fetch the image data from Flickr URL & Populate the cell */
                cell.spinner.startAnimating()
                cell.alpha = 0.5
                cell.imageView.image = nil
                cell.layer.cornerRadius = 10
                
                let urlString = imageUrlsOfAlbum[indexPath.item]
                DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                    let data = try? Data(contentsOf: URL(string: urlString)!)
                    
                    DispatchQueue.main.async {
                        if let data = data, let imageUrlStrings = self?.imageUrlsOfAlbum {
                            if indexPath.item < imageUrlStrings.count && urlString == imageUrlStrings[indexPath.item] {
                                cell.spinner.stopAnimating()
                                cell.alpha = 1.0
                                cell.layer.cornerRadius = 0
                                let image = UIImage(data: data)
                                cell.imageView.image = image
                                self?.fetchedImagesOfAlbum[indexPath.item] = image
                            }
                        }
                    }
                }
            }
        } else {
            cell.imageView.image = UIImage(data: pinPhotos[indexPath.item].data)
            cell.alpha = selectedItems[indexPath.item] ? 0.3 : 1.0
        }

        return cell
    }
    
}

extension PhotoAlbumVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if button.isEnabled && (imageUrlsOfAlbum.count == 0 || fetchedImagesOfAlbum[indexPath.item] != nil) {
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
    
}

extension PhotoAlbumVC: FirstPageDownloadObserver {
    
    func notifyObserverOfDownloadResult(_ result: PageDownloadResult) {
        DispatchQueue.main.async {
            self.pageDownloadResult = result
            self.updateUIBasedOnDownloadStatus(false)
            if let downloadError = result.error {
                print("Error Downloading First Page of Image URLs: \(downloadError)")
                self.showAlert(message: "Error while downloading images.")
            } else {
                self.updateUIViews()
            }
        }
    }
    
}

