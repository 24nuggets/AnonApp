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
        
        
        let titles = ["Welcome to the Nut House", "Post (Crack) On Your College's Page", "Vote, Reply, & Share With Other Students"]
        let subtitles = ["", "Cracks disappear from the feed after 48 hrs", "A score of -5 deletes a crack"]
        let images = ["NutHouse Icon","Better Resolution Exerpt - Main Feed","Better Resolution Exerpt - Vote and Reply"]
        //if you change num of pages change button target less than guard
        let numOfPages = 3
        
        for x in 0..<numOfPages{
            let pageView = UIView(frame: CGRect(x: CGFloat(x) * holderView.frame.size.width, y: 0, width: holderView.frame.size.width, height: holderView.frame.size.height))
            scrollView.addSubview(pageView)
            
            let label = UILabel()
            let label2 = UILabel()
            
            // the image size is ratio is width: 349, height: 620
            var imageView:UIImageView
            if x == 0{
                imageView = UIImageView()
               // imageView = UIImageView(frame: CGRect(x: (pageView.frame.size.width / 2) - (((pageView.frame.size.height - 130 - 60 - 15) * (349/620)) / 2), y: 120, width: (pageView.frame.size.height - 130 - 60 - 15) * (349/620), height: pageView.frame.size.height - 130 - 60 - 15))
                 
           }else{
             //imageView = UIImageView(frame: CGRect(x: (pageView.frame.size.width / 2) - (((pageView.frame.size.height - 90 - 15) * (349/620)) / 2), y: 20, width: (pageView.frame.size.height - 90 - 15) * (349/620), height: pageView.frame.size.height - 90 - 15))
                imageView = UIImageView()
            }
            let button = UIButton(frame: CGRect(x: 15, y: pageView.frame.size.height - 60, width: pageView.frame.size.width - 30, height: 50))
           //  let button = UIButton()
            
            label.textAlignment = .center
            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = 0
            if x==0 {
            label.font = UIFont(name: "GillSans-UltraBold", size: 54)
            }else{
               label.font = UIFont(name: "GillSans-Bold", size: 40)
            }
            label.textColor = UIColor(hexString: "ffaf46")
            pageView.addSubview(label)
            label.text = titles[x]
            
            label2.textAlignment = .center
            label2.lineBreakMode = .byWordWrapping
            label2.numberOfLines = 0
           
            label2.font = UIFont(name: "GillSans-Bold", size: 32)
            
            label2.textColor = UIColor(hexString: "ffaf46")
            label2.text = subtitles[x]
            
            if x != 0{
            pageView.addSubview(label2)
            pageView.addConstraintWithFormat(format: "H:|-15-[v0]-15-|", views: label2)
            }
            pageView.addConstraintWithFormat(format: "H:|-15-[v0]-15-|", views: label)
           
            pageView.backgroundColor = darktint
            
            imageView.contentMode = .scaleAspectFit
            imageView.image = UIImage(named: images[x])
            imageView.layer.cornerRadius = 40
            imageView.clipsToBounds = true
            imageView.backgroundColor = .black
           
            
            pageView.addSubview(imageView)
            
            
            pageView.addConstraintWithFormat(format: "V:|-15-[v0]", views: label)
          
            let spacer1 = UIView()
            let spacer2 = UIView()
            spacer1.backgroundColor = darktint
            spacer2.backgroundColor = darktint
            pageView.addSubview(spacer1)
            pageView.addSubview(spacer2)
            if x == 0 {
            pageView.addConstraintWithFormat(format: "V:[v0][v2][v1][v3(==v2)]-60-|", views: label,imageView,spacer1, spacer2 )
            }else{
                let spacer3 = UIView()
                spacer3.backgroundColor = darktint
                pageView.addSubview(spacer3)
                pageView.addConstraintWithFormat(format: "V:[v0][v3][v1][v4(==v3)][v2][v5(==v3)]-60-|", views: label,imageView, label2, spacer1, spacer2, spacer3 )
            }
          
            if x == 0 {
            imageView.heightAnchor.constraint(equalToConstant: (pageView.frame.size.width - 30)).isActive = true
            }else if x == 1 {
            imageView.heightAnchor.constraint(equalToConstant: (pageView.frame.size.width - 30) * (675 / 905)).isActive = true
            }
            else if x == 2 {
               imageView.heightAnchor.constraint(equalToConstant: (pageView.frame.size.width - 30) * (740 / 920)).isActive = true
            }
            imageView.widthAnchor.constraint(equalToConstant: pageView.frame.size.width - 30).isActive = true
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
        scrollView.contentSize = CGSize(width: Int(holderView.frame.size.width) * numOfPages, height: 0)
        scrollView.isPagingEnabled = true
    }
    
    @objc func didTapButton(_ button:UIButton){
        guard button.tag < 3 else{
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
