//
//  Reply.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/25/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import Foundation
import Firebase

class Reply{
    var replyText:String?
    var replyScore:Int?
    var timePosted:Timestamp?
    var replyID:String?
    var author:String?
    
    
    
    init(aScore:Int, aKey:String, atimePosted:Timestamp, aText:String, aAuthor:String){
    
        replyScore=aScore
        author=aAuthor
        replyText=aText
        timePosted=atimePosted
        replyID=aKey
    }
    

}
