//
//  Quip.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/19/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import Foundation
import Firebase

class Quip{
    
    //attributes of single quip
    var quipText:String?
    var channel:String?
    var quipScore:Int?
    var timePosted:Timestamp?
    var user:String?
    var quipID:String?
    var channelKey:String?
    var parentKey:String?
    var quipReplies:Int?
    
    
  
    
    //initialization function for reading
   /* init(text:String, bowl:String, time:Timestamp, score:Int, myQuipID:String, myChannelKey:String,myParent:String?,author:String){
        quipText = text
        channel = bowl
        timePosted = time
        quipScore = score
        quipID = myQuipID
        user=author
        channelKey=myChannelKey
        parentKey=myParent
    }
 */
    init(text:String, bowl:String, time:Timestamp, score:Int, myQuipID:String, replies:Int){
        quipText = text
        channel = bowl
        timePosted = time
        quipScore = score
        quipID = myQuipID
        quipReplies=replies
    }
    
    init(text:String, bowl:String, time:Timestamp, score:Int, myQuipID:String, author:String,replies:Int){
        quipText = text
        channel = bowl
        timePosted = time
        quipScore = score
        quipID = myQuipID
        user=author
        quipReplies=replies
    }
    init(score:Int, replies:Int, myQuipID:String){
        quipScore = score
        quipID = myQuipID
        
        quipReplies=replies
    }
    
    //increments the score of individual quip by 1
    func incrementQuipScore(){
        quipScore! += 1
    }
    
    //decrements the score of indivual quip by 1 then checks if score is -5 or less
    func decrementQuipScore(){
        quipScore! -= 1
        if quipScore! < -4{
            deleteQuip()
        }
    }
    
    //returns either seconds, minutes, hrs, months, days, or years since post
    //looks for first one of the above that is not 0
    func getTimeElapsed()->String{
       return ""
    }
    
    
    //deletes quip
    private func deleteQuip(){
        
    }
    
}
