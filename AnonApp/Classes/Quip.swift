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
   var imageRef:String?
   var gifID:String?
  var seen:Bool = false
   var tempScore:Int?
    var isReply = false
 var quipParent:String?
 
    
    
    
  
    
    //loading quip to user page
    init(text:String, bowl:String, time:Timestamp, score:Int, myQuipID:String, replies:Int, myImageRef:String?, myGifID:String?, myChannelKey:String?, myParentChannelKey:String?, isReply:Bool?, aquipParent:String?){
        quipText = text
        channel = bowl
        timePosted = time
        quipScore = score
        quipID = myQuipID
        quipReplies=replies
        tempScore = score
        imageRef=myImageRef
        gifID=myGifID
        channelKey=myChannelKey
        parentKey=myParentChannelKey
        if let aReply = isReply{
        self.isReply=aReply
        quipParent=aquipParent
        }
    }
    
    //initializing reply
    init(aScore:Int, aKey:String, atimePosted:Timestamp, aText:String, aAuthor:String, image:String?, gif:String?, quipParentID:String?){
           tempScore = aScore
           quipScore=aScore
           user=aAuthor
           quipText=aText
           timePosted=atimePosted
           quipID=aKey
            quipParent=quipParentID
           imageRef=image
           gifID=gif
            isReply = true
       }
    //loading quip to feed page
    init(text:String, bowl:String, time:Timestamp, score:Int, myQuipID:String, author:String,replies:Int, myImageRef:String?, myGifID:String?){
        quipText = text
        channel = bowl
        timePosted = time
        quipScore = score
        quipID = myQuipID
        user=author
        quipReplies=replies
        imageRef=myImageRef
        gifID=myGifID
        tempScore = score
    }
   
    init(score:Int, replies:Int, myQuipID:String){
        quipScore = score
        quipID = myQuipID
        tempScore = score
        quipReplies=replies
    }
    
    init(myQuipID:String, auser:String?, parentchannelKey:String?, achannelkey:String?, atimePosted:Timestamp?, text:String?, quipParent:String?, isReply:Bool?, imageRef:String?, gifid:String?){
        parentKey=parentchannelKey
        channelKey=achannelkey
        quipID = myQuipID
        user = auser
        timePosted=atimePosted
        quipText=text
        self.quipParent = quipParent
        self.isReply = isReply ?? false
        self.imageRef = imageRef
        self.gifID = gifid
    }
    
    
    func setScore(aScore:Int){
        quipScore = aScore
        tempScore = aScore
    }
    
   
    deinit{
        
    }
 
   
    
}
