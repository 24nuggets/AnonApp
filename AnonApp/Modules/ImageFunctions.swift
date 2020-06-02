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
    
    func getImage(myQuipImageRef:String, feedTable:UITableView){
        myImageRef = myQuipImageRef
        
        if let cacheImage = imageCache.object(forKey: myQuipImageRef as NSString){
            let heightConstraint = self.heightAnchor.constraint(equalToConstant: cacheImage.size.height)
            self.addConstraint(heightConstraint)
                    feedTable.beginUpdates()
                    feedTable.endUpdates()
            self.layer.cornerRadius = 8.0
                   self.clipsToBounds = true
            self.image = cacheImage as? UIImage
        }
        else{
         let downloadRef = storageRef.child(myQuipImageRef)
         let downloadTask = downloadRef.getData(maxSize: 1 * 1024 * 1024) { (data, error) in
                if let error = error {
                            print("error: \(error.localizedDescription)")
                            return
                }
                else{
                    DispatchQueue.main.async {
                        if self.myImageRef == myQuipImageRef{
                           
                                     
                            if let myImage = UIImage(data: data!) {
                                
                                let width = self.frame.size.width
                                let newImage = resizeImage(image: myImage, targetSize: CGSize(width: width, height: width * 2 ))
                                imageCache.setObject(newImage, forKey: myQuipImageRef as NSString)
                                let heightConstraint = self.heightAnchor.constraint(equalToConstant: newImage.size.height)
                                self.addConstraint(heightConstraint)
                                        feedTable.beginUpdates()
                                        feedTable.endUpdates()
                                self.layer.cornerRadius = 8.0
                                       self.clipsToBounds = true
                               
                                                 
                                          self.image = newImage
                                runningRequestsImageViews.removeValue(forKey: self)
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
    
   
    
    func getImageFromGiphy(gifID: String, feedTable:UITableView){
        
        if let cacheGif = imageCache.object(forKey: gifID as NSString){
            let media = cacheGif as? GPHMedia
            self.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: media!.aspectRatio).isActive = true
            feedTable.beginUpdates()
            feedTable.endUpdates()
            self.layer.cornerRadius = 8.0
            self.clipsToBounds = true
            self.media = media
        }
        else {
           let task = GiphyCore.shared.gifByID(gifID) { (response, error) in
                      if let media = response?.data {
                          DispatchQueue.main.async {
                              
                              
                               
                            imageCache.setObject(media, forKey: gifID as NSString)
                            
                                                                
                            self.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: media.aspectRatio).isActive = true
                            feedTable.beginUpdates()
                            feedTable.endUpdates()
                            self.layer.cornerRadius = 8.0
                            self.clipsToBounds = true
                            self.media = media
                            runningRequestsGifViews.removeValue(forKey: self)
                              
                              
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

