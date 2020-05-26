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
    var startDate:String?
    var key:String?
    var parent:String?
    var parentKey:String?
    var priority:Int?
    
    
    init(name:String, start:String?, akey:String, aparent:String?, aparentkey:String?, apriority:Int?){
        channelName = name
        startDate = start
        key=akey
        parent=aparent
        parentKey=aparentkey
        priority=apriority  
    }
    
    
    
}
