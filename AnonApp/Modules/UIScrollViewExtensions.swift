//
//  UIScrollViewExtensions.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 6/29/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit


extension UIScrollView: UIGestureRecognizerDelegate{
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
       if let _ = self as? UITableView {
        return false
       }else{
        if self.contentOffset.x == 0{
            if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer{
                let velocity = gestureRecognizer.velocity(in: self.superview)
                return abs(velocity.x) > abs(velocity.y)
            }
        
        }else{
            return false
        }
        }
        return false
    }
    /*
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
     
       if self.contentOffset.x == 0{
        if let _ = self as? UITableView {
              return true
        }else{
            if gestureRecognizer == panGestureRecognizer{
                let velocity = panGestureRecognizer.velocity(in: self.superview)
                let x = velocity.x
                let y = velocity.y
                    if x > 0 && abs(x) > abs(y){
                        return true
                    }
                       
            }
                
        }
         
        }
        return false
    }
    
    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let _ = self as? UITableView{
           if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer{
                let velocity = gestureRecognizer.velocity(in: self.superview)
                return abs(velocity.y) > abs(velocity.x)
            }
        }else{
            if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer{
                let velocity = gestureRecognizer.velocity(in: self.superview)
                return abs(velocity.x) > abs(velocity.y)
            }
        }
        return true
    }
     
    */
    
}
