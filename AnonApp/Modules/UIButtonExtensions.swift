//
//  UIButtonExtensions.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 5/25/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//


import UIKit

extension UIButton{
    
    
   func changeButtonWeight(){
       if #available(iOS 13.0, *) {
                  let selectedSymbolConfig = UIImage.SymbolConfiguration(weight: .bold)
                  let unselectedSymbolConfig = UIImage.SymbolConfiguration(weight: .regular)
           self.setPreferredSymbolConfiguration(selectedSymbolConfig, forImageIn: UIControl.State.selected)
           self.setPreferredSymbolConfiguration(unselectedSymbolConfig, forImageIn: UIControl.State.normal)
                  
              } else {
                  // Fallback on earlier versions
              }
       
   }
    func selectCategoryButton()->CALayer{
        let borderWidth = 2
        
        
        let border = CALayer()
        border.backgroundColor = UIColor.black.cgColor
        border.frame = CGRect(x: 0,y: Int(self.frame.size.height) - borderWidth, width:Int(self.frame.size.width), height:borderWidth)
        self.layer.addSublayer(border)
        return border
    }
   
}


