//
//  UpcomingChannelCells.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/11/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import GiphyUISDK
import GiphyCoreSDK
import Firebase



let imageCache = NSCache<NSString,AnyObject>()
private var runningRequestsImageViews:[CustomImageView:StorageDownloadTask]=[:]
private var runningRequestsGifViews:[GPHMediaView:Operation]=[:]

class CustomImageView:UIImageView{
    let storageRef = Storage.storage().reference()
    var myImageRef:String?
    var activityIndicator:UIActivityIndicatorView?
    var myHeightConstraint: NSLayoutConstraint?
    
    func addActivityIndicator(){
        activityIndicator = UIActivityIndicatorView()
        if let myactivityIndicator = activityIndicator{
        myactivityIndicator.hidesWhenStopped = true
            if #available(iOS 14.0, *) {
                myactivityIndicator.style = .gray
            } else {
                // Fallback on earlier versions
                myactivityIndicator.style = .gray
            }
            
        myactivityIndicator.center = self.center
        
        self.addSubview(myactivityIndicator)
            myactivityIndicator.translatesAutoresizingMaskIntoConstraints = false
            placeAtTheCenterWithView(view: myactivityIndicator)
        myactivityIndicator.startAnimating()
        }
    }
    
    func placeAtTheCenterWithView(view: UIView) {

        self.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1.0, constant: 0))

        self.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1.0, constant: 0))
    }
   
    
    func getImage(myQuipImageRef:String, feedTable:UITableView){
        myImageRef = myQuipImageRef
        
        if let cacheImage = imageCache.object(forKey: myQuipImageRef as NSString){
            if let myHeightConstraint = self.myHeightConstraint{
                myHeightConstraint.isActive = false
            }
          //  DispatchQueue.main.async {
             
            let heightConstraint = self.heightAnchor.constraint(equalToConstant: cacheImage.size.height)
                
            self.addConstraint(heightConstraint)
             //       feedTable.beginUpdates()
             //       feedTable.endUpdates()
                self.activityIndicator?.stopAnimating()
            self.layer.cornerRadius = 8.0
                   self.clipsToBounds = true
            self.image = cacheImage as? UIImage
         //   }
        }
        else{
         let downloadRef = storageRef.child(myQuipImageRef)
         let downloadTask = downloadRef.getData(maxSize: 1 * 1024 * 1024) {[weak self] (data, error) in
                if let error = error {
                            print("error: \(error.localizedDescription)")
                            return
                }
                else{
                    DispatchQueue.main.async {
                        if self?.myImageRef == myQuipImageRef{
                           
                                     
                            if let myImage = UIImage(data: data!) {
                                if let aself = self{
                                 let width = aself.frame.size.width
                                let newImage = resizeImage(image: myImage, targetSize: CGSize(width: width, height: width * 2 ))
                                imageCache.setObject(newImage, forKey: myQuipImageRef as NSString)
                              //      self?.superview?.heightAnchor.constraint(greaterThanOrEqualToConstant: newImage.size.height).isActive = true
                                let heightConstraint = aself.heightAnchor.constraint(equalToConstant: newImage.size.height)
                                    if let myHeightConstraint = aself.myHeightConstraint{
                                        myHeightConstraint.isActive = false
                                    }
                                 feedTable.beginUpdates()
                                aself.addConstraint(heightConstraint)
                                       
                                        feedTable.endUpdates()
                                    aself.activityIndicator?.stopAnimating()
                                aself.layer.cornerRadius = 8.0
                                aself.clipsToBounds = true
                               
                                                 
                                          aself.image = newImage
                                runningRequestsImageViews.removeValue(forKey: aself)
                                }
                                }
                            
                                          
                        }
                    }
                    
                }
                                        
            }
            runningRequestsImageViews[self]=downloadTask
        }
        
                                
         
     }
    
    func cancelLoad(){
        if let task = runningRequestsImageViews[self]{
        task.cancel()
            runningRequestsImageViews.removeValue(forKey:   self)
        }
    }
    func getCropRatio()->CGFloat{
        let widthRat = self.frame.size.width/self.frame.size.height
           let widthRatio = CGFloat(widthRat)
           return widthRatio
       }
    
}

extension GPHMediaView{
    
    func addActivityIndicator(){
           let myactivityIndicator = UIActivityIndicatorView()
           
           myactivityIndicator.hidesWhenStopped = true
               if #available(iOS 13.0, *) {
                myactivityIndicator.style = .medium
               } else {
                   // Fallback on earlier versions
                   myactivityIndicator.style = .gray
               }
               
           myactivityIndicator.center = self.center
           
           self.addSubview(myactivityIndicator)
               myactivityIndicator.translatesAutoresizingMaskIntoConstraints = false
               placeAtTheCenterWithView(view: myactivityIndicator)
           myactivityIndicator.startAnimating()
           
       }
       
       func placeAtTheCenterWithView(view: UIView) {

           self.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1.0, constant: 0))

           self.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1.0, constant: 0))
       }
   
    
    func getImageFromGiphy(gifID: String, feedTable:UITableView){
        
        if let cacheGif = imageCache.object(forKey: gifID as NSString){
            let media = cacheGif as? GPHMedia
          //   DispatchQueue.main.async {
             self.removeConstraints(self.constraints)
            self.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: media!.aspectRatio).isActive = true
         //   feedTable.beginUpdates()
         //   feedTable.endUpdates()
            self.layer.cornerRadius = 8.0
            self.clipsToBounds = true
            for subview in self.subviews{
                if let mysubview = subview as? UIActivityIndicatorView{
                    mysubview.stopAnimating()
                }
            }
            self.media = media
            
        //    }
        }
        else {
           let task = GiphyCore.shared.gifByID(gifID) {[weak self] (response, error) in
                      if let media = response?.data {
                          DispatchQueue.main.async {
                              
                              
                               
                            imageCache.setObject(media, forKey: gifID as NSString)
                            
                            if let aself = self{
                            feedTable.beginUpdates()
                                aself.removeConstraints(aself.constraints)
                            aself.widthAnchor.constraint(equalTo: aself.heightAnchor, multiplier: media.aspectRatio).isActive = true
                            
                            feedTable.endUpdates()
                            aself.layer.cornerRadius = 8.0
                            aself.clipsToBounds = true
                            for subview in aself.subviews{
                                if let mysubview = subview as? UIActivityIndicatorView{
                                    mysubview.stopAnimating()
                                }
                            }
                            aself.media = media
                            runningRequestsGifViews.removeValue(forKey: aself)
                            }
                              
                          }
                            
                          
              }
              
              
          }
        runningRequestsGifViews[self]=task
        }
       
          
      }
    
    func cancelLoad(){
        if let task = runningRequestsGifViews[self]{
        task.cancel()
            runningRequestsGifViews.removeValue(forKey: self)
        }
    }
    
   
    
}

