//
//  UIViewExtension.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 5/28/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit

extension UIView{
    func addConstraintWithFormat(format:String, views:UIView...){
        var viewDictionary = [String:UIView]()
        for (index,view) in views.enumerated(){
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewDictionary[key] = view
        }
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewDictionary))
    }
    var parentViewController: UIViewController? {
         var parentResponder: UIResponder? = self
         while parentResponder != nil {
             parentResponder = parentResponder?.next
             if let viewController = parentResponder as? UIViewController {
                 return viewController
             }
         }
         return nil
     }
}




