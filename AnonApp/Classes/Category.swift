//
//  Category.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/24/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import Foundation


class Category{
    
    var categoryName:String?
    var activeUpcomingKey:String?
    var pastKey:String?
    
    
    init(name:String, akeyUpcomingActive:String,  aKeyPast:String){
        categoryName = name
        
        activeUpcomingKey=akeyUpcomingActive
        pastKey=aKeyPast
        
    }
    
    
    
}
