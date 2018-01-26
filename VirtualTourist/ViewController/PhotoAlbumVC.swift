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
    var pinPhotos = [Photo]() // Photo objects in Core Data
    var pageDownloadResult: PageDownloadResult!
    var imageUrlsOfAlbum = [String]() // Remote Flickr Image URLs
    var downloadedImageCount = 0, savedImageDataCount = 0, everVisibleItemMaxIndex = 0, imageDataEverSaved = false
    let albumSize = 24, pageSize = 4 * 24 // 1 page = 4 albums
    var albumNumberInPage = 1, pageNumber = 1
    var downloadedImages = [UIImage?]()
    var downloadedImageIndices = Set<Int>()
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
                updateUIViewsUponNewImageUrls()
            } else {
                // Download of First Page In Progress
                updateUIBasedOnDownloadStatus(true)
            }
        } else {
            selectedItems = Array(repeating: false, count: pinPhotos.count)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !imageDataEverSaved && downloadedImageCount > 0 {
            coreDataStack.performOperation { (mainContext) in
                for photo in self.pinPhotos {
                    mainContext.delete(photo)
                }
                for uiImage in self.downloadedImages {
                    if let uiImage = uiImage, let data = UIImagePNGRepresentation(uiImage) {
                        let _ = Photo(data: data, pin: self.pin, context: mainContext)
                    }
                }
            }
        }
    }
    
    private func updateUIViewsUponNewImageUrls() {
        let fetchedImageUrlsOfPage = pageDownloadResult.imageUrls!
        if fetchedImageUrlsOfPage.count > 0 {
            let from = (albumNumberInPage - 1) * albumSize, to = min(from + albumSize, fetchedImageUrlsOfPage.count)
            imageUrlsOfAlbum = Array(fetchedImageUrlsOfPage[from..<to])
            downloadedImageCount = 0
            savedImageDataCount = 0
            everVisibleItemMaxIndex = 0
            imageDataEverSaved = false
            selectedItems = Array(repeating: false, count: to - from)
            downloadedImages = Array(repeating: nil, count: to - from)
            downloadedImageIndices = Set<Int>()
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
                        this.showAlert(message: ErrorMessages.errorWhileDownloadingImages)
                    } else {
                        this.updateUIViewsUponNewImageUrls()
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
        button.isEnabled = !downloading
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        //super.didRotate(from: fromInterfaceOrientation)
        
        configureUIBasedOnOrientation()
    }
    
    @IBAction func buttonPressed(_ sender: Any) {
        if selectedItemCount == 0 {
            // Scroll the Collection View to the top
            let firstIndexPath = IndexPath(item: 0, section: 0)
            collectionView.scrollToItem(at: firstIndexPath, at: .top, animated: true)
            
            displayNextAlbumOfPhotos()
        } else {
            removeSelectedPhotos()
        }
    }
    
    private func displayNextAlbumOfPhotos() {
        if pageDownloadResult == nil {
            downloadFirstPageOfImageUrls()
            return
        }
        
        let fetchedImageUrls = pageDownloadResult.imageUrls!, totalOfPages = pageDownloadResult.totalOfPages!
        
        albumNumberInPage += 1
        let from = (albumNumberInPage - 1) * albumSize, to = min(from + albumSize, fetchedImageUrls.count)
        imageUrlsOfAlbum = Array(fetchedImageUrls[from..<to])
        downloadedImageCount = 0
        savedImageDataCount = 0
        everVisibleItemMaxIndex = 0
        imageDataEverSaved = false
        selectedItems = Array(repeating: false, count: to - from)
        downloadedImages = Array(repeating: nil, count: to - from)
        downloadedImageIndices = Set<Int>()
        collectionView.reloadData()
        
        /* Pre-fetch New Random Page of Image URLs */
        if to == fetchedImageUrls.count {
            button.isEnabled = false
            
            albumNumberInPage = 0
            pageNumber = 1 + numericCast(arc4random_uniform(numericCast(totalOfPages)))
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
                        if error != nil {
                            this.showAlert(message: ErrorMessages.errorWhileDownloadingImages)
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
                if selectedItems[i] {
                    downloadedImageCount -= 1
                    downloadedImageIndices.remove(i)
                } else {
                    unselectedImageUrls.append(imageUrlsOfAlbum[i])
                    unselectedImages.append(downloadedImages[i])
                }
            }
            savedImageDataCount = 0
            everVisibleItemMaxIndex = 0
            imageDataEverSaved = false

            imageUrlsOfAlbum = unselectedImageUrls
            downloadedImages = unselectedImages
            selectedItems = Array(repeating: false, count: imageUrlsOfAlbum.count)
        } else {
            var deletingPinPhotos = [Photo](), remainingPinPhotos = [Photo]()
            for i in 0..<selectedItems.count {
                if selectedItems[i] {
                    deletingPinPhotos.append(pinPhotos[i])
                } else {
                    remainingPinPhotos.append(pinPhotos[i])
                }
            }
            coreDataStack.performOperation { (mainContext) in
                for photo in deletingPinPhotos {
                    mainContext.delete(photo)
                }
            }
            pinPhotos = remainingPinPhotos
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
        
        if imageUrlsOfAlbum.count == 0 {
            cell.imageView.image = UIImage(data: pinPhotos[indexPath.item].data)
            cell.alpha = selectedItems[indexPath.item] ? 0.3 : 1.0
            return cell
        }

        everVisibleItemMaxIndex = max(everVisibleItemMaxIndex, indexPath.item)
        
        if let image = downloadedImages[indexPath.item] {
            cell.imageView.image = image
            cell.alpha = selectedItems[indexPath.item] ? 0.3 : 1.0
            return cell
        }
        
        /* Fetch the image data from Flickr URL & Populate the cell */
        cell.spinner.startAnimating()
        cell.alpha = 0.5
        cell.imageView.image = nil
        cell.layer.cornerRadius = 10
        
        let urlString = imageUrlsOfAlbum[indexPath.item]
        downloadImage(imagePath: urlString) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let this = self, let data = data else { return }
                guard indexPath.item < this.imageUrlsOfAlbum.count,
                    urlString == this.imageUrlsOfAlbum[indexPath.item],
                    !this.downloadedImageIndices.contains(indexPath.item) else {
                        return
                }
                cell.spinner.stopAnimating()
                cell.alpha = 1.0
                cell.layer.cornerRadius = 0
                let image = UIImage(data: data)
                cell.imageView.image = image
                this.downloadedImages[indexPath.item] = image
                
                // Persist when all the Ever-Visible items have their image data downloaded from Flickr URLs
                this.downloadedImageCount += 1
                this.downloadedImageIndices.insert(indexPath.item)
                if this.downloadedImageCount == (this.everVisibleItemMaxIndex + 1) {
                    let capturedEverVisibleItemMaxIndex = this.everVisibleItemMaxIndex
                    this.coreDataStack.performOperation { (mainContext) in
                        if !this.imageDataEverSaved && this.pinPhotos.count > 0 {
                            for photo in this.pinPhotos {
                                mainContext.delete(photo)
                            }
                            this.pinPhotos.removeAll()
                        }
                        for i in this.savedImageDataCount...capturedEverVisibleItemMaxIndex {
                            let uiImage = this.downloadedImages[i]!
                            let data = UIImagePNGRepresentation(uiImage)!
                            let photo = Photo(data: data, pin: this.pin, context: mainContext)
                            this.pinPhotos.append(photo)
                        }
                        this.savedImageDataCount = capturedEverVisibleItemMaxIndex + 1
                        this.imageDataEverSaved = true
                        
                        if this.downloadedImageCount == this.imageUrlsOfAlbum.count {
                            // All the images of album have been downloaded, and they are being saved to disk via Core Data
                            // Now Clear imageUrlsOfAlbum so that removing photos after this point of time works
                            this.imageUrlsOfAlbum.removeAll()
                            this.downloadedImages.removeAll()
                            this.downloadedImageIndices.removeAll()
                        }
                    }
                }
            }
        }
        return cell
    }
    
    private func downloadImage(imagePath:String, completionHandler: @escaping (_ imageData: Data?, _ errorString: String?) -> Void) {
        let request = URLRequest(url: URL(string: imagePath)!)
        let task = URLSession.shared.dataTask(with: request) { data, response, downloadError in
            if downloadError != nil {
                completionHandler(nil, "Could not download image \(imagePath)")
            } else {
                completionHandler(data, nil)
            }
        }
        task.resume()
    }
    
}

extension PhotoAlbumVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if button.isEnabled && (imageUrlsOfAlbum.count == 0 || downloadedImages[indexPath.item] != nil) {
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
                self.showAlert(message: ErrorMessages.errorWhileDownloadingImages)
            } else {
                self.updateUIViewsUponNewImageUrls()
            }
        }
    }
    
}

