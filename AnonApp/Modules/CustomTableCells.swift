//
//  CustomTableCells.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 5/25/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import GiphyUISDK
import GiphyCoreSDK


protocol MyCellDelegate: AnyObject {
    func btnUpTapped(cell: QuipCells)
    func btnDownTapped(cell: QuipCells)
    func btnSharedTapped(cell: QuipCells)
    func btnEllipsesTapped(cell:QuipCells)
    func btnRepliesTapped(cell: QuipCells)
    
}

protocol MyCellDelegate2: AnyObject {
    
    func arrowTapped(cell:CategoryCells)
}
protocol MyCellDelegate3: AnyObject {
    
    func arrowTap(cell:ChannelCells)
}

class UpcomingChannelCells:UITableViewCell{
   
    @IBOutlet weak var channelName: UILabel!
    
    @IBOutlet weak var startDate: UILabel!
    
    
}

class ChannelCells: UITableViewCell {

    @IBOutlet weak var channelName: UILabel!
    
    @IBOutlet weak var date: UILabel!
    
    @IBOutlet weak var arrowBtn: UIButton!
    weak var delegate: MyCellDelegate3?
    
    override func awakeFromNib() {
           super.awakeFromNib()
        arrowBtn.setTitleColor(darktint, for: .normal)    }
    
    @IBAction func arrowTap(_ sender: Any) {
        delegate?.arrowTap(cell: self)
    }
   

}
class CategoryCells:UITableViewCell{
    @IBOutlet weak var categoryName: UILabel!
    
    @IBOutlet weak var arrowBtn: UIButton!
    
    
    weak var delegate: MyCellDelegate2?
    
    override func awakeFromNib() {
       super.awakeFromNib()
    arrowBtn.setTitleColor(darktint, for: .normal)    }
    
    @IBAction func arrowTapped(_ sender: Any) {
        delegate?.arrowTapped(cell: self)
        
    }
    
}

class QuipCells:UITableViewCell{
    
  
    
    @IBOutlet weak var quipText: UILabel!
    @IBOutlet weak var upButton: UIButton!
    @IBOutlet weak var score: UILabel!
    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var timePosted: UILabel!
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    @IBOutlet weak var categoryLabel: UILabel!
    
  
    
    weak var delegate: MyCellDelegate?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.autoresizingMask = .flexibleHeight
    }
    
    var table:UITableView?
    
    var gifID: String? {
            didSet {
                
                if let url = gifID {
                    //self.image = UIImage(named: "loading")
                    myGifView = GPHMediaView()
                    self.addGifViewToTableCell()
                    
                    
                    GPHMedia.loadGifUsingCacheWithUrlString(gifID: url) { [weak self](gif, isCached, gifId) -> (Void) in
                        // set the image only when we are still displaying the content for the image we finished downloading
                       
                        if url == gifId {
                            if let aGifView = self?.myGifView{
                                
                                if isCached{
                                    
                                    aGifView.removeConstraints(aGifView.constraints)
                                    aGifView.widthAnchor.constraint(equalTo: aGifView.heightAnchor, multiplier: gif.aspectRatio).isActive = true
                                   aGifView.layer.cornerRadius = 8.0
                                   aGifView.clipsToBounds = true
                                           for subview in aGifView.subviews{
                                               if let mysubview = subview as? UIActivityIndicatorView{
                                                   mysubview.stopAnimating()
                                               }
                                           }
                                    
                                }else{
                                DispatchQueue.main.async {
                                    self?.table?.beginUpdates()
                                    aGifView.removeConstraints(aGifView.constraints)
                                    aGifView.widthAnchor.constraint(equalTo: aGifView.heightAnchor, multiplier: gif.aspectRatio).isActive = true
                                    self?.table?.endUpdates()
                                   aGifView.layer.cornerRadius = 8.0
                                   aGifView.clipsToBounds = true
                                   for subview in aGifView.subviews{
                                       if let mysubview = subview as? UIActivityIndicatorView{
                                           mysubview.stopAnimating()
                                       }
                                   }
                                    
                                }
                                }
                                    aGifView.media = gif
                                
                                
                            }
                        }
                    }
                }
                else {
                    self.myGifView?.media = nil
                }
            }
        }
    
    var aQuip:Quip? {
        didSet{
            if let myQuip = aQuip{
                                         
                
               // self.categoryLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
                self.quipText?.text = myQuip.quipText
                
                if let numOfReplies = myQuip.quipReplies {
                if numOfReplies == 1{
                    self.replyButton.setTitle("\(numOfReplies) Reply", for: .normal)
                }else if numOfReplies > 1{
                    self.replyButton.setTitle("\(numOfReplies) Replies", for: .normal)
                }
                else{
                   self.replyButton.setTitle("Replies", for: .normal)
                    }
                }
                if let aQuipScore=myQuip.tempScore{
                    self.score?.text = String(aQuipScore)
                }
                
                
                                             
            }
        }
    }
    
    
    @IBAction func btnRepliesTapped(_ sender: Any) {
        delegate?.btnRepliesTapped(cell: self)
    }
    
    @IBAction func btnUpTapped(_ sender: Any) {
       
        delegate?.btnUpTapped(cell: self)
    }
    
    @IBAction func btnDownTapped(_ sender: Any) {
        
         delegate?.btnDownTapped(cell: self)
    }
    
    @IBAction func btnSharedTapped(_ sender: Any) {
        
         delegate?.btnSharedTapped(cell: self)
    }
    
    @IBAction func ellipsesTapped(_ sender: Any) {
        delegate?.btnEllipsesTapped(cell: self)
    }
    
    
    var myGifView : GPHMediaView? = nil
    
    let myImageView : CustomImageView = {
    let imgView = CustomImageView()
        
   
    return imgView
    }()
    
    
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        myGifView?.media = nil
        
        myImageView.image = nil
        gifID = nil
        table = nil
        myImageView.removeConstraints(myImageView.constraints)
        myGifView?.removeConstraints(myGifView?.constraints ?? [])
        myImageView.removeFromSuperview()
        myGifView?.removeFromSuperview()
        upButton.isSelected = false
        downButton.isSelected = false
        upButton.tintColor = .lightGray
        downButton.tintColor = .lightGray
        if replyButton != nil {
        replyButton.isHidden = false
        }
        if shareButton != nil {
            shareButton.isHidden = false
        }
        myGifView?.cancelLoad()
        myImageView.cancelLoad()
        
        
    }
    
   
    func upToDown(quipScore:Int, quip:Quip?)->Int{
        
                   upToDown2(quipScore: quipScore, quip: quip)
               
       return -2
           
       }
    func upToDown2(quipScore:Int, quip:Quip?){
           
                      
                             self.upButton.isSelected = false
                             self.downButton.isSelected = true
                         
                         self.upButton.tintColor = UIColor.lightGray
        self.downButton.tintColor = UIColor(hexString: "ffaf46")
                        
                       let originalScore = Int(self.score.text!)!
                           
                             let newScore = originalScore - 2
                             self.score.text = String(newScore)
         
           quip?.tempScore=newScore
                  
       
              
          }
    
       
    func noneToDown(quipScore:Int, quip:Quip?)->Int{
        noneToDown2(quipScore: quipScore, quip: quip)
         return  -1
           
       }
    
    func noneToDown2(quipScore:Int, quip:Quip?){
        let isAdmin = UserDefaults.standard.bool(forKey: "isAdmin")
        if !isAdmin{
           self.downButton.isSelected=true
           self.downButton.tintColor = UIColor(hexString: "ffaf46")
        }
               let originalScore = Int(self.score.text!)
               let newScore = originalScore! - 1
               self.score.text = String(newScore)
           if let aquip = quip {
                      aquip.tempScore=newScore
                  }
           
              
          }
       
    func downToNone(quipScore:Int, quip:Quip?)->Int{
             downToNone2(quipScore: quipScore, quip: quip)
        return 1
           
       }
    
    func downToNone2(quipScore:Int, quip:Quip?){
                  self.downButton.isSelected=false
                       self.downButton.tintColor = UIColor.lightGray
                           let originalScore = Int(self.score.text!)
                           let newScore = originalScore! + 1
                           self.score.text = String(newScore)
          if let aquip = quip {
                     aquip.tempScore=newScore
                 }
          
             
         }
       
    func downToUp(quipScore:Int, quip:Quip?)->Int{
                    downToUp2(quipScore: quipScore, quip: quip)
                       return 2
           
       }
    func downToUp2(quipScore:Int, quip:Quip?){
                 self.downButton.isSelected=false
                        self.upButton.isSelected=true
                   self.upButton.tintColor = UIColor(hexString: "ffaf46")
                   self.downButton.tintColor = UIColor.lightGray
                        let originalScore = Int(self.score.text!)
                   let newScore = originalScore! + 2
                        self.score.text = String(newScore)
                  if let aquip = quip {
                             aquip.tempScore=newScore
                         }
                  
        
    }
    func noneToUp(quipScore:Int, quip:Quip?)->Int{
       noneToUp2(quipScore: quipScore, quip: quip)
         return 1
           
       }
    func noneToUp2(quipScore:Int, quip:Quip?){
        let isAdmin = UserDefaults.standard.bool(forKey: "isAdmin")
        if !isAdmin{
         self.upButton.isSelected=true
        self.upButton.tintColor = UIColor(hexString: "ffaf46")
        }
              let originalScore = Int(self.score.text!)
         let newScore = originalScore! + 1
         if let aquip = quip {
             aquip.tempScore=newScore
         }
              self.score.text = String(newScore)
        
            
        }
    
    func upToNone(quipScore:Int, quip:Quip?)->Int{
        upToNone2(quipScore: quipScore, quip: quip)
          return -1
           
       }
    func upToNone2(quipScore:Int, quip:Quip?){
           self.upButton.isSelected = false
            self.upButton.tintColor = UIColor.lightGray
                 let originalScore = Int(self.score.text!)
            let newScore = originalScore! - 1
                 self.score.text = String(newScore)
           if let aquip = quip {
                      aquip.tempScore=newScore
                  }
             
              
          }
   
    
   
    
    func addGifViewToTableCell(){
          
        self.contentView.addSubview(self.myGifView!)
          self.myGifView?.translatesAutoresizingMaskIntoConstraints = false
                     
        let bottomConstraint = NSLayoutConstraint(item: self.contentView, attribute: .bottom, relatedBy: .equal, toItem: self.myGifView, attribute: .bottom, multiplier: 1, constant: 40)
          let leadingContraint = NSLayoutConstraint(item: self.myGifView, attribute: .leading, relatedBy: .equal, toItem: self.contentView, attribute: .leading, multiplier: 1, constant: 10)
          let trailingConstraint = NSLayoutConstraint(item: self.contentView, attribute: .trailing, relatedBy: .equal, toItem: self.myGifView, attribute: .trailing, multiplier: 1, constant: 77)
          let topConstraint = NSLayoutConstraint(item: self.myGifView, attribute: .top, relatedBy: .equal, toItem: self.quipText, attribute: .bottom, multiplier: 1, constant: 4)
        self.myGifView?.heightAnchor.constraint(equalToConstant: 250).isActive = true
            
          self.contentView.addConstraints([bottomConstraint,leadingContraint,trailingConstraint, topConstraint])
        self.myGifView?.addActivityIndicator()
       
      }
  
    
    func addImageViewToTableCell(){
             
             self.contentView.addSubview(self.myImageView)
             self.myImageView.translatesAutoresizingMaskIntoConstraints = false
                               
             let bottomConstraint = NSLayoutConstraint(item: self.contentView, attribute: .bottom, relatedBy: .equal, toItem: self.myImageView, attribute: .bottom, multiplier: 1, constant: 40)
             let leadingContraint = NSLayoutConstraint(item: self.myImageView, attribute: .leading, relatedBy: .equal, toItem: self.contentView, attribute: .leading, multiplier: 1, constant: 10)
             let trailingConstraint = NSLayoutConstraint(item: self.contentView, attribute: .trailing, relatedBy: .equal, toItem: self.myImageView, attribute: .trailing, multiplier: 1, constant: 77)
             let topConstraint = NSLayoutConstraint(item: self.myImageView, attribute: .top, relatedBy: .equal, toItem: self.quipText, attribute: .bottom, multiplier: 1, constant: 4)
        self.myImageView.myHeightConstraint = self.myImageView.heightAnchor.constraint(equalToConstant: 250)
        self.myImageView.myHeightConstraint?.isActive = true
        
             self.contentView.addConstraints([bottomConstraint,leadingContraint,trailingConstraint, topConstraint])
        self.myImageView.addActivityIndicator()
           
         }
    
    
    
}


