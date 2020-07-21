//
//  Utilities.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/21/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import Foundation
import Firebase
import GiphyUISDK
import GiphyCoreSDK



func timeSincePost(timePosted:Double, currentTime:Double)->String{
    let timeSincePost = (currentTime - timePosted)/1000
    let years = floor(timeSincePost/31536000)
    if years > 0 {
        if years == 1 {
            return (String(format: "%.0f",years) + " year ago")
        }
        else{
             return (String(format: "%.0f",years) + " years ago")
        }
       
    }
    let months = floor((timeSincePost)/2592000)
    if months > 0 {
        if months == 1 {
            return (String(format: "%.0f",months) + " month ago")
        }
        else {
            return (String(format: "%.0f",months) + " months ago")
        }
        
    }
    let days = floor((timeSincePost)/86400)
    if days > 0 {
        if days == 1 {
            return (String(format: "%.0f",days) + " day ago")
        }
        else{
            return (String(format: "%.0f",days) + " days ago")
        }
        
    }
    let hrs = floor((timeSincePost)/3600)
    if hrs > 0 {
        if hrs == 1 {
             return (String(format: "%.0f",hrs) + " hr ago")
        }
        else{
             return (String(format: "%.0f",hrs) + " hrs ago")
        }
       
    }
    let minutes = floor((timeSincePost)/60)
    if minutes > 0 {
        if minutes == 1 {
             return (String(format: "%.0f",minutes) + " minute ago")
        }
        else {
             return (String(format: "%.0f",minutes) + " minutes ago")
        }
       
    }
    let seconds = floor(timeSincePost)
    if seconds == 1 {
        return (String(format: "%.0f",seconds) + " second ago")
    }
    else{
        return (String(format: "%.0f",seconds) + " seconds ago")
    }
    
    
   /* var months = floor((timeSincePost-(years*31536000))/2592000)
       var days = floor((timeSincePost  - (months*2592000))/86400)
       var hrs = floor((timeSincePost  - (days*86400))/3600)
       var minutes = floor((timeSincePost  - (days*3600))/60)
       var seconds = floor((timeSincePost  - (days*60))/60)
    */
}

 func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
    let size = image.size

    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height

    // Figure out what our orientation is, and use that to form the rectangle
    var newSize: CGSize
    if(widthRatio > heightRatio) {
        newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
        newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
    }

    // This is the rect that we've calculated out and this is what is actually used below
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

    // Actually do the resizing to the rect using the ImageContext stuff
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    if let newImage = UIGraphicsGetImageFromCurrentImageContext(){
    UIGraphicsEndImageContext()

    return newImage
    }
    return UIImage()
}

extension UIView {
   func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

 

