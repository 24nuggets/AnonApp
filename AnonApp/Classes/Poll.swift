//
//  Poll.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 11/13/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import Foundation



class Poll{
    
    var votes:[Double]
    var selected:Int
    
    
    
    init(avotes:[Double], aselected:Int){
        votes = avotes
        selected = aselected
       
        
    }
    
    deinit{
        
    }
    
}
