//
//  Utilities.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/21/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import Foundation
import Firebase




func timeSincePost(timePosted:Double, currentTime:Double)->String{
    var _:String
    let timeSincePost = (currentTime - timePosted)/1000
    let years = floor(timeSincePost/31536000)
    if years > 0 {
        return (String(years) + " years ago")
    }
    let months = floor((timeSincePost)/2592000)
    if months > 0 {
        return (String(months) + " months ago")
    }
    let days = floor((timeSincePost)/86400)
    if days > 0 {
        return (String(days) + " days ago")
    }
    let hrs = floor((timeSincePost)/3600)
    if hrs > 0 {
        return (String(hrs) + " hrs ago")
    }
    let minutes = floor((timeSincePost)/60)
    if minutes > 0 {
        return (String(minutes) + " minutes ago")
    }
    let seconds = floor(timeSincePost)
    return (String(seconds) + " seconds ago")
    
   /* var months = floor((timeSincePost-(years*31536000))/2592000)
       var days = floor((timeSincePost  - (months*2592000))/86400)
       var hrs = floor((timeSincePost  - (days*86400))/3600)
       var minutes = floor((timeSincePost  - (days*3600))/60)
       var seconds = floor((timeSincePost  - (days*60))/60)
    */
}



