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
    var priority:Int?
    var bigCat:String?
    
    
    init(name:String, aPriority:Int?, aBigCat:String?){
        categoryName = name
        bigCat = aBigCat
        priority = aPriority
        
    }
    
    deinit{
        
    }
    
}
