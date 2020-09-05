//
//  Channel.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/19/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import Foundation


class Channel{
    
    var channelName:String?
    var startDate:Date?
    var endDate:Date?
    var key:String?
    var parent:String?
    var parentKey:String?
    var priority:Int?
    var aemail:String?
    
    
    init(name:String, akey:String, aparent:String?, aparentkey:String?, apriority:Int?, astartDate:Date?, aendDate:Date?){
        channelName = name
        startDate = astartDate
        endDate = aendDate
        key=akey
        parent=aparent
        parentKey=aparentkey
        priority=apriority  
    }
    
    init(name:String, akey:String, email:String){
        channelName = name
        aemail = email
        key=akey
        
    }
    
    deinit{
        
    }
    
}
