//
//  Quip.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/19/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import Foundation

class Quip{
    
    //attributes of single quip
    var quipText:String?
    var channel:String?
    var quipScore:Int?
    var timePosted:String?
    var user:String?
    var quipID:String?
    
    
    //initialization function for writing
    init(text:String, bowl:String, time:String, aUser:String){
        quipText=text
        channel=bowl
        quipScore=0
        timePosted=time
        user=aUser
    }
    
    //initialization function for reading
    init(text:String, bowl:String, time:String, score:Int, myQuipID:String){
        quipText = text
        channel = bowl
        timePosted = time
        quipScore = score
        quipID = myQuipID
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
