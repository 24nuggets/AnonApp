//
//  ViewControllerExtensions.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 5/25/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//


import UIKit



class myUIViewController: UIViewController{
    var percentDrivenInteractiveTransition: UIPercentDrivenInteractiveTransition!
    var panGestureRecognizer: UIPanGestureRecognizer!
    
    func addGesture() {
        
        
        guard navigationController?.viewControllers.count ?? 0 > 1 else {
            return
        }
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        self.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc func handlePanGesture(_ panGesture: UIPanGestureRecognizer) {
        
        let percent = max(panGesture.translation(in: view).x, 0) / view.frame.width
        
        switch panGesture.state {
            
        case .began:
            if navigationController != nil{
                self.navigationController?.delegate = self
            
            _ = navigationController?.popViewController(animated: true)
            }
        case .changed:
            if let percentDrivenInteractiveTransition = percentDrivenInteractiveTransition {
                percentDrivenInteractiveTransition.update(percent)
            }
            
        case .ended:
            let velocity = panGesture.velocity(in: view).x
            
            // Continue if drag more than 50% of screen width or velocity is higher than 1000
            if percent > 0.5 || velocity > 1000 {
                percentDrivenInteractiveTransition.finish()
            } else {
                percentDrivenInteractiveTransition.cancel()
            }
            
        case .cancelled, .failed:
            if let percentDrivenInteractiveTransition = percentDrivenInteractiveTransition {
            percentDrivenInteractiveTransition.cancel()
            }
        default:
            break
        }
    }
  
   
}

extension myUIViewController:UINavigationControllerDelegate{
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
          
          return SlideAnimatedTransitioning()
          
      }
      
      public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
          
          navigationController.delegate = nil
          
          if panGestureRecognizer.state == .began {
              percentDrivenInteractiveTransition = UIPercentDrivenInteractiveTransition()
              percentDrivenInteractiveTransition.completionCurve = .easeOut
          } else {
              percentDrivenInteractiveTransition = nil
          }
          
          return percentDrivenInteractiveTransition
      }
  
}

extension myUIViewController:UIGestureRecognizerDelegate{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
           return true
       }
}


extension UIViewController{
    func hideKeyboardWhenTappedAround() {
                let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
                tap.cancelsTouchesInView = false
                view.addGestureRecognizer(tap)
            }

            @objc func dismissKeyboard() {
                view.endEditing(true)
            }
      
    
}




