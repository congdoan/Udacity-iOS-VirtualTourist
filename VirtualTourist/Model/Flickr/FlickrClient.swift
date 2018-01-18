//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Cong Doan on 1/12/18.
//  Copyright © 2018 Cong Doan. All rights reserved.
//

//import Foundation
import MapKit

class  FlickrClient {
    
    static let shared = FlickrClient()
    
    let commonMethodParameters: [String: Any] = [
        Constants.FlickrParameterKeys.Method : Constants.FlickrParameterValues.SearchMethod,
        Constants.FlickrParameterKeys.APIKey : Constants.FlickrParameterValues.APIKey,
        Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.MediumURL,
        Constants.FlickrParameterKeys.Format : Constants.FlickrParameterValues.ResponseFormat,
        Constants.FlickrParameterKeys.SafeSearch : Constants.FlickrParameterValues.UseSafeSearch,
        Constants.FlickrParameterKeys.NoJSONCallback : Constants.FlickrParameterValues.DisableJSONCallback
    ]
    
    private func flickrURLFromParameters(_ parameters: [String: Any]) -> URL {
        var components = URLComponents()
        
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        
        components.queryItems = [URLQueryItem]()
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    private func bboxStringFromCoordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        let minLon = max(coordinate.longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minLat = max(coordinate.latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maxLon = min(coordinate.longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maxLat = min(coordinate.latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minLon),\(minLat),\(maxLon),\(maxLat)"
    }

    private func sendError(_ errorDescription: String,
                           _ domain: String,
                           _ recipientCompletionHandler: (_ result: AnyObject?, _ totalOfPages: Int?, _ error: Error?) -> Void) {
        let userInfo = [NSLocalizedDescriptionKey : errorDescription]
        recipientCompletionHandler(nil, nil, NSError(domain: domain, code: 1, userInfo: userInfo))
    }
    
    private func startTaskForRequest(_ request: URLRequest,
                                     completionHandler: @escaping (_ resultDictionary: AnyObject?, _ totalOfPages: Int?, _ error: Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            let domain = "FlickrClient.startTaskForRequest"
            
            if let error = error {
                self.sendError(error.localizedDescription, domain, completionHandler)
                print("ERROR: \(error)")
                return
            }
            
            guard let data = data else {
                self.sendError("No data was returned by the request.", domain, completionHandler)
                return
            }
            
            if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode < 200 || statusCode > 299 {
                let errormessage = "Status Code \(statusCode). " + String(data: data, encoding: .utf8)!
                self.sendError(errormessage, domain, completionHandler)
                return
            }
            
            do {
                let parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
                completionHandler(parsedResult, nil, nil)
            } catch {
                let dataString: String = String(data: data, encoding: .utf8)!
                let errormessage = "Could not parse the below data as JSON:\n\(dataString)"
                self.sendError(errormessage, domain, completionHandler)
            }
        }
        task.resume()
    }
    
    // Fetch list of Image URL strings around the given coordinate
    func imageUrlsAroundCoordinate(_ coordinate: CLLocationCoordinate2D,
                                   pageNumber: Int = 1,
                                   pageSize: Int = 96,
                                   completionHandler: @escaping (_ imageUrls: AnyObject?, _ totalOfPages: Int?, _ error: Error?) -> Void) {
        var methodParameters: [String: Any] = commonMethodParameters
        methodParameters[Constants.FlickrParameterKeys.Page] = pageNumber
        methodParameters[Constants.FlickrParameterKeys.PerPage] = pageSize
        methodParameters[Constants.FlickrParameterKeys.BoundingBox] = bboxStringFromCoordinate(coordinate)
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        print("REQUEST: \(request.url!)")
        startTaskForRequest(request) { (resultDictionary, totalOfPages, error) in
            let domain = "FlickrClient.imagesAroundCoordinate"
            if let error = error {
                self.sendError(error.localizedDescription, domain, completionHandler)
                return
            }
            
            let parsedResult = resultDictionary!
            
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                self.sendError("Flickr API returned an error. See error code and message in '\(parsedResult)'",
                                domain, completionHandler)
                return
            }
            
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject],
                  let photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                self.sendError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' and '\(Constants.FlickrResponseKeys.Photo)' in \(parsedResult)",
                                domain, completionHandler)
                return
            }
            
            /* Calculate the actual number of pages based total, max number of results per search, and perpage */
            guard let total = photosDictionary[Constants.FlickrResponseKeys.Total] as? String else {
                self.sendError("Cannot find keys 'total' in \(photosDictionary)",
                                domain, completionHandler)
                return
            }
            print("photoArray.size=\(photoArray.count), total=\(total)")
            let maxNumberOfResultsPerSearch = 4100
            let actualNumberOfReturnedImages = min(Int(total)!, maxNumberOfResultsPerSearch)
            let actualNumberOfPages = (actualNumberOfReturnedImages / pageSize) + (actualNumberOfReturnedImages % pageSize != 0 ? 1 : 0)
            print("actualNumberOfPages         : \(actualNumberOfPages)")

            let imageUrls = photoArray.map {(photoDictionary) in
                photoDictionary[Constants.FlickrResponseKeys.MediumURL] as! String//Unexpectedly found nil while unwrapping an Optional value
            }
            completionHandler(imageUrls as AnyObject, actualNumberOfPages, nil)
        }
    }

}
