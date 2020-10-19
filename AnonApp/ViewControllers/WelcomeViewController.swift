//
//  WelcomeViewController.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 10/17/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class WelcomeViewController: UIViewController {
    
    
    @IBOutlet weak var holderView: UIView!
    
    let scrollView = UIScrollView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Analytics.logEvent(AnalyticsEventTutorialBegin, parameters: nil)
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configure()
        displayLicenAgreement()
    }
    
    private func configure(){
        //set up scroll view
        scrollView.frame = holderView.bounds
        holderView.addSubview(scrollView)
        
        
        let titles = ["Welcome", "", "", ""]
        let images = ["Tutorial Redo Page 1","Tutorial Redo Page 2","Tutorial Redo Page 3", "Tutorial Page 4 Final"]
        //if you change num of pages change button target less than guard
        let numOfPages = 4
        
        for x in 0..<numOfPages{
            let pageView = UIView(frame: CGRect(x: CGFloat(x) * holderView.frame.size.width, y: 0, width: holderView.frame.size.width, height: holderView.frame.size.height))
            scrollView.addSubview(pageView)
            
            let label = UILabel(frame: CGRect(x: 10, y: 10, width: pageView.frame.size.width - 20, height: 120))
            
            // the image size is ratio is width: 349, height: 620
            var imageView:UIImageView
            if x == 0{
                imageView = UIImageView(frame: CGRect(x: (pageView.frame.size.width / 2) - (((pageView.frame.size.height - 130 - 60 - 15) * (349/620)) / 2), y: 120, width: (pageView.frame.size.height - 130 - 60 - 15) * (349/620), height: pageView.frame.size.height - 130 - 60 - 15))
                 
           }else{
             imageView = UIImageView(frame: CGRect(x: (pageView.frame.size.width / 2) - (((pageView.frame.size.height - 90 - 15) * (349/620)) / 2), y: 20, width: (pageView.frame.size.height - 90 - 15) * (349/620), height: pageView.frame.size.height - 90 - 15))
            }
            let button = UIButton(frame: CGRect(x: 10, y: pageView.frame.size.height - 60, width: pageView.frame.size.width - 20, height: 50))
            
            label.textAlignment = .center
            label.font = UIFont(name: "Helvetica-Bold", size: 48)
            label.textColor = UIColor(hexString: "ffaf46")
            pageView.addSubview(label)
            label.text = titles[x]
            
            holderView.backgroundColor = darktint
            
            imageView.contentMode = .scaleAspectFit
            imageView.image = UIImage(named: images[x])
            imageView.layer.cornerRadius = 40
            imageView.clipsToBounds = true
           
            
            pageView.addSubview(imageView)
            imageView.centerXAnchor.constraint(equalTo: pageView.centerXAnchor).isActive = true
            
            button.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 20)
            button.backgroundColor = UIColor(hexString: "ffaf46")
            button.setTitle("Continue", for: .normal)
            button.layer.cornerRadius = 15
            if x == numOfPages - 1{
                button.setTitle("Get Cracking", for: .normal)
            }
            button.tag = x + 1
            pageView.addSubview(button)
        }
        scrollView.contentSize = CGSize(width: holderView.frame.size.width * 3, height: 0)
        scrollView.isPagingEnabled = true
    }
    
    @objc func didTapButton(_ button:UIButton){
        guard button.tag < 4 else{
            //dismiss
            Analytics.logEvent(AnalyticsEventTutorialComplete, parameters: nil)
            Core.shared.setIsNotNewUser()
            dismiss(animated: true, completion: nil)
            return
        }
        //scroll to next page
        scrollView.setContentOffset(CGPoint(x: CGFloat(button.tag) * holderView.frame.size.width, y: 0), animated: true)
    }
    
     func displayLicenAgreement(){
          let message = "We use Apple's Standard End User License Agreement and to use this app you must agree to the terms outlined in the EULA."
          //create alert
          let alert = UIAlertController(title: "License Agreement", message: message, preferredStyle: .alert)
           let defaults = UserDefaults.standard
          //create Decline button
          let declineAction = UIAlertAction(title: "Decline" , style: .destructive){ (action) -> Void in
              //DECLINE LOGIC GOES HERE
              self.displayLicenAgreement()
              
              defaults.set(false, forKey: "isAppAlreadyLaunchedOnce")
          }
          
          //create Accept button
          let acceptAction = UIAlertAction(title: "Accept", style: .default) { (action) -> Void in
              //ACCEPT LOGIC GOES HERE
              defaults.set(true, forKey: "isAppAlreadyLaunchedOnce")
          }
          
          //add task to tableview buttons
          alert.addAction(declineAction)
          alert.addAction(acceptAction)
          
          
        self.present(alert,animated: true)
    
      }
   

}
