//
//  CollectionViewCellFeed.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 6/23/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class CollectionCellFeed:UICollectionViewCell, MyCellDelegate{
    
   
     var currentTime:Double?
    var myFeedController:ViewControllerFeed?
     var newQuips:[Quip?] = []
     var hotQuips:[Quip?] = []
   
    lazy var MenuLauncher:ellipsesMenuFeed = {
            let launcher = ellipsesMenuFeed()
         launcher.feedController = myFeedController
             return launcher
        }()
    
    
   
    func btnDownTapped(cell: QuipCells) {
        
    }
     func btnUpTapped(cell: QuipCells) {
    }
    
    
    func btnEllipsesTapped(cell: QuipCells) {
          
       }
    
    func btnSharedTapped(cell: QuipCells) {
                     
                       
    }
    
    func generateDynamicLink(aquip:Quip, cell: QuipCells){
        var components = URLComponents()
        components.scheme = "https"
        components.host = "anonapp.page.link"
        components.path = "/quips"
        let quipIDQueryItem = URLQueryItem(name: "quipid", value: aquip.quipID)
        components.queryItems = [quipIDQueryItem]
        guard let linkparam = components.url else {return}
        print(linkparam)
        let dynamicLinksDomainURIPrefix = "https://anonapp.page.link"
        guard let sharelink = DynamicLinkComponents.init(link: linkparam, domainURIPrefix: dynamicLinksDomainURIPrefix) else {return}
        if let bundleId = Bundle.main.bundleIdentifier {
            sharelink.iOSParameters = DynamicLinkIOSParameters(bundleID: bundleId)
        }
        //change to app store id
        sharelink.iOSParameters?.appStoreID = "962194608"
        sharelink.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        
        sharelink.socialMetaTagParameters?.title = aquip.quipText
        sharelink.socialMetaTagParameters?.descriptionText = aquip.channel
        if let myImage = aquip.imageRef {
             FirebaseStorageService.sharedInstance.getDownloadURL(imageRef: myImage, completion: {[weak self] (url) in
                print(url)
                sharelink.socialMetaTagParameters?.imageURL = url
                guard let longDynamicLink = sharelink.url else { return }
                 sharelink.shorten {[weak self] (url, warnings, error) in
                               if let error = error{
                                   print(error)
                                   return
                               }
                               if let warnings = warnings{
                                   for warning in warnings{
                                       print(warning)
                                   }
                               }
                               guard let url = url else {return}
                                
                               self?.showShareViewController(url: url)
                           }
            })
        }else{
            if let myGif = aquip.gifID {
            let gifURL = "api.giphy.com/v1/gifs/\(myGif)?api_key=2OFJFhBB22BPrYcLHLs2JtaMA5xSrQ2Y"
            print(gifURL)
            sharelink.socialMetaTagParameters?.imageURL = URL(string: gifURL)
            
            }
        
        guard let longDynamicLink = sharelink.url else { return }
        print("The long URL is: \(longDynamicLink)")
            sharelink.shorten {[weak self] (url, warnings, error) in
                if let error = error{
                    print(error)
                    return
                }
                if let warnings = warnings{
                    for warning in warnings{
                        print(warning)
                    }
                }
                guard let url = url else {return}
                print(url)
                self?.showShareViewController(url: url)
            }
            
        }
    }
    
    func showShareViewController(url:URL){
        let myactivity1 = "Check out this quip on Quipit!"
        let myactivity2 = url
                             
                        
                               // set up activity view controller
        let firstactivity = [myactivity1, myactivity2] as [Any]
                        let activityViewController = UIActivityViewController(activityItems: firstactivity, applicationActivities: nil)
                              activityViewController.popoverPresentationController?.sourceView = myFeedController?.view // so that iPads won't crash

                               // exclude some activity types from the list (optional)
                        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.addToReadingList, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.markupAsPDF, UIActivity.ActivityType.openInIBooks, UIActivity.ActivityType.print]

                               // present the view controller
                               myFeedController?.present(activityViewController, animated: true, completion: nil)
    }
    
    // MARK: - Like/Dislike Logic
     
     //each if statement:
     //1. updates cell to reflect changes
     //2. adds votes to firebase array
     //3. adds votes to newlikesdislikes map - this is never read just used to push changes to database
     //4. adds votes to current likesdislikes map - this is so changes are reflected when scrolling back and forth
     //5. adds user id to dict so it can be easily found when votes in firestore are commited
    
    func downPressedForOtherCell(aQuip:Quip, cell:QuipCells){
        if cell.upButton.isSelected {
                        if let aQuipScore = aQuip.quipScore{
                         cell.upToDown2(quipScore: aQuipScore, quip: aQuip)
            }
        }else if cell.downButton.isSelected {
            if let aQuipScore = aQuip.quipScore{
             cell.downToNone2(quipScore: aQuipScore, quip: aQuip)
                            }
        }else{
          if let aQuipScore = aQuip.quipScore{
             cell.noneToDown2(quipScore: aQuipScore, quip:aQuip)
                }
        }
                            
    }
    
    func upPressedForOtherCell(aQuip:Quip, cell:QuipCells){
        if cell.upButton.isSelected {
                     if let aQuipScore = aQuip.quipScore{
                         cell.upToNone2(quipScore: aQuipScore, quip:aQuip)
            }
        } else if cell.downButton.isSelected {
                         if let aQuipScore = aQuip.quipScore{
                             cell.downToUp2(quipScore: aQuipScore, quip:aQuip)
            }
        }else{
        if let aQuipScore = aQuip.quipScore{
            cell.noneToUp2(quipScore: aQuipScore, quip:aQuip)
            }
        }
    }
    
   func downButtonPressed(aQuip:Quip, cell:QuipCells){
          if cell.upButton.isSelected {
                 if let aQuipScore = aQuip.quipScore{
                  let diff = cell.upToDown(quipScore: aQuipScore, quip: aQuip)
                      if let aID = aQuip.quipID{
                          if let aAuthor = aQuip.user{
                          
                            myFeedController?.myNewLikesDislikesMap[aID] = -1
                          myFeedController?.myLikesDislikesMap[aID] = -1
                         myFeedController?.myUserMap[aID]=aQuip.user
                              myFeedController?.updateVotesFirebase(diff: diff, quipID: aID, aUID: aAuthor)
                          }
                      }
              }
          }
          else if cell.downButton.isSelected {
                 if let aQuipScore = aQuip.quipScore{
                  let diff = cell.downToNone(quipScore: aQuipScore, quip: aQuip)
                      if let aID = aQuip.quipID{
                          if let aAuthor = aQuip.user{
                          
                          myFeedController?.myNewLikesDislikesMap[aID]=0
                          myFeedController?.myLikesDislikesMap[aID]=0
                          myFeedController?.myUserMap[aID]=aQuip.user
                              myFeedController?.updateVotesFirebase(diff: diff, quipID: aID, aUID: aAuthor)
                          }
                      }
                  
              }
          }
          else{
               if let aQuipScore = aQuip.quipScore{
                  let diff = cell.noneToDown(quipScore: aQuipScore, quip:aQuip)
                  if let aID = aQuip.quipID{
                      if let aAuthor = aQuip.user{
                      
                      myFeedController?.myNewLikesDislikesMap[aID] = -1
                      myFeedController?.myLikesDislikesMap[aID] = -1
                      myFeedController?.myUserMap[aID]=aQuip.user
                          myFeedController?.updateVotesFirebase(diff: diff, quipID: aID, aUID: aAuthor)
                      }
                  }
              }
              
          }
          
      }
    func upButtonPressed(aQuip:Quip, cell:QuipCells){
          if cell.upButton.isSelected {
              if let aQuipScore = aQuip.quipScore{
                  let diff = cell.upToNone(quipScore: aQuipScore, quip:aQuip)
                  if let aID = aQuip.quipID{
                      if let aAuthor = aQuip.user{
                      
                        myFeedController?.myNewLikesDislikesMap[aID]=0
                        myFeedController?.myLikesDislikesMap[aID]=0
                      myFeedController?.myUserMap[aID]=aQuip.user
                          myFeedController?.updateVotesFirebase(diff: diff, quipID: aID, aUID: aAuthor)
                      }
                      }
                      
              }
               }
               else if cell.downButton.isSelected {
                  if let aQuipScore = aQuip.quipScore{
                      let diff = cell.downToUp(quipScore: aQuipScore, quip:aQuip)
                          if let aID = aQuip.quipID{
                              if let aAuthor = aQuip.user{
                              
                              myFeedController?.myNewLikesDislikesMap[aID] = 1
                              myFeedController?.myLikesDislikesMap[aID] = 1
                              myFeedController?.myUserMap[aID]=aQuip.user
                                  myFeedController?.updateVotesFirebase(diff: diff, quipID: aID, aUID: aAuthor)
                              }
                          }
                      }
                  }
               else{
                  if let aQuipScore = aQuip.quipScore{
                      let diff = cell.noneToUp(quipScore: aQuipScore, quip:aQuip)
                      if let aID = aQuip.quipID{
                          if let aAuthor = aQuip.user{
                          
                          myFeedController?.myNewLikesDislikesMap[aID] = 1
                          myFeedController?.myLikesDislikesMap[aID] = 1
                          myFeedController?.myUserMap[aID]=aQuip.user
                          myFeedController?.updateVotesFirebase(diff: diff, quipID: aID, aUID: aAuthor)
                          }
                      }
                  }
               }
          
      }
    
    
 
    
    
}

class CollectionViewCellFeedRecent: CollectionCellFeed, UITableViewDelegate, UITableViewDataSource  {
   
    private var refreshControl=UIRefreshControl()
    private var firestoreQuips:[Quip?] = []
    private var myScores:[String:Any]=[:]
    private var moreRecentQuipsFirebase:Bool = false
    private var moreRecentQuipsFirestore:Bool = false
   private var cellHeights = [IndexPath: CGFloat]()
    
    @IBOutlet weak var feedTable: UITableView!
    
    override func awakeFromNib() {
       super.awakeFromNib()
       feedTable.delegate = self
       feedTable.dataSource = self
        self.feedTable.rowHeight = UITableView.automaticDimension
        self.feedTable.estimatedRowHeight = 500.0
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        
        feedTable.refreshControl = refreshControl
        
      
    }
    
    @objc func refreshData(){
        
        updateNew(){
            
        }
    }
    
    func updateNew(completion: @escaping ()->()){
        self.refreshControl.beginRefreshing()
        self.firestoreQuips = []
        self.myScores = [:]
        self.moreRecentQuipsFirebase = false
        if let myChannelKey = myFeedController?.myChannel?.key{
            if let aUid = myFeedController?.uid {
            FirestoreService.sharedInstance.getUserLikesDislikesForChannelOrUser(aUid: aUid, aKey: myChannelKey) { [weak self](myLikesDislikesMap) in
            self?.myFeedController?.myLikesDislikesMap = myLikesDislikesMap
            
            FirebaseService.sharedInstance.getNewScoresFeed(myChannelKey: myChannelKey) { [weak self](myScores, currentTime,  moreRecentQuipsFirebase) in
                self?.myScores = myScores
                self?.currentTime = currentTime
                self?.moreRecentQuipsFirebase = moreRecentQuipsFirebase
                if let myChannelName = self?.myFeedController?.myChannel?.channelName{
                    FirestoreService.sharedInstance.getNewQuipsFeed(myChannelKey: myChannelKey, myChannelName: myChannelName) { [weak self](newQuips, moreRecentQuipsFirestore) in
                        self?.firestoreQuips = newQuips
                        self?.mergeFirestoreFirebaseNewQuips()
                        self?.moreRecentQuipsFirestore = moreRecentQuipsFirestore
                        
                            self?.feedTable.reloadData()
                            self?.refreshControl.endRefreshing()
                            completion()
                            }
                        }
                    }
                }
                
            }
        
       
       
        }
        
    }
    
    func loadMoreRecent(){
              moreRecentQuipsFirestore=false
           
           if let myChannelKey = myFeedController?.myChannel?.key{
               if moreRecentQuipsFirebase==true{
                   moreRecentQuipsFirebase=false
               FirebaseService.sharedInstance.getMoreNewScoresFeed(myChannelKey: myChannelKey) {[weak self] (myScores, moreRecentQuipsFirebase) in
                   if let aself = self{
                   self?.myScores = aself.myScores.merging(myScores, uniquingKeysWith: { (_, new) -> Any in
                       new
                   })
                   }
                   
                   //need to make sure firebase is always ahead of firestore
                   if self?.moreRecentQuipsFirestore ?? false{
                       if let myChannelName = self?.myFeedController?.myChannel?.channelName{
                           FirestoreService.sharedInstance.loadMoreNewQuipsFeed(myChannelKey: myChannelKey, channelName: myChannelName) { [weak self](newQuips, moreRecentQuipsFirestore) in
                               if let aself = self{
                               self?.firestoreQuips = aself.firestoreQuips + newQuips
                               self?.mergeFirestoreFirebaseNewQuips()
                               self?.feedTable.reloadData()
                                //have to reload table before setting these to true
                               self?.moreRecentQuipsFirebase = moreRecentQuipsFirebase
                               self?.moreRecentQuipsFirestore = moreRecentQuipsFirestore
                               }
                           }
                           
                       }
                   }else{
                       self?.mergeFirestoreFirebaseNewQuips()
                       self?.feedTable.reloadData()
                       self?.moreRecentQuipsFirebase = moreRecentQuipsFirebase
                   }
                   
               }
               }else{
                   if let myChannelName = self.myFeedController?.myChannel?.channelName{
                       FirestoreService.sharedInstance.loadMoreNewQuipsFeed(myChannelKey: myChannelKey, channelName: myChannelName) {[weak self] (newQuips, moreRecentQuipsFirestore) in
                           if let aself = self{
                           self?.firestoreQuips = aself.firestoreQuips + newQuips
                           self?.mergeFirestoreFirebaseNewQuips()
                           self?.feedTable.reloadData()
                           }
                                               //have to reload table before setting these to true
                       
                           self?.moreRecentQuipsFirestore = moreRecentQuipsFirestore
                   }
                   }
               }
           }
           
           
             
              
          }
       
       func mergeFirestoreFirebaseNewQuips(){
           newQuips = []
           for aQuip in firestoreQuips{
               guard let myQuipInfo = myScores[aQuip?.quipID ?? ""] as? [String:Int] else {continue}
               aQuip?.setScore(aScore:myQuipInfo["s"] ?? 0)
               aQuip?.quipReplies = myQuipInfo["r"]
               newQuips.append(aQuip)
           }
           
       }
    //gets number of sections for tableview
       func numberOfSections(in tableView: UITableView) -> Int {
           return 1
       }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newQuips.count
       }
       
       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        
            
          let cell = feedTable.dequeueReusableCell(withIdentifier: "feedCell", for: indexPath) as? QuipCells
                
          
                if newQuips.count > 0 {
                
                    if let myQuip = self.newQuips[indexPath.row]{
                        cell?.aQuip = myQuip
                           if let myImageRef = myQuip.imageRef  {
                               
                               cell?.addImageViewToTableCell()
                             cell?.myImageView.getImage(myQuipImageRef: myImageRef,  feedTable: self.feedTable)
                                                       //        }
                        }
                         else if let myGifID = myQuip.gifID  {
                                cell?.addGifViewToTableCell()
                                cell?.myGifView.getImageFromGiphy(gifID: myGifID, feedTable:self.feedTable)
                                                                    
                                                               }
                            
                        
                if let dateVal = myQuip.timePosted?.seconds{
                    let milliTimePost = dateVal * 1000
                if let aCurrentTime = self.currentTime{
                        cell?.timePosted.text = timeSincePost(timePosted: Double(milliTimePost), currentTime: aCurrentTime)
                                               }
                                           }
                if let aID = myQuip.quipID{
                if self.myFeedController?.myLikesDislikesMap[aID] == 1{
                    cell?.upButton.isSelected=true
                                        
                                                       cell?.upButton.tintColor = UIColor(red: 152.0/255.0, green: 212.0/255.0, blue: 186.0/255.0, alpha: 1.0)
                                               }
                                               else if self.myFeedController?.myLikesDislikesMap[aID] == -1{
                                                       cell?.downButton.isSelected=true
                                                      
                                                       cell?.downButton.tintColor = UIColor(red: 152.0/255.0, green: 212.0/255.0, blue: 186.0/255.0, alpha: 1.0)
                                                                                                             
                                               }
                                           }
                }
                
                else{
                    return UITableViewCell()
                }
                cell?.downButton.changeButtonWeight()
                     cell?.upButton.changeButtonWeight()
                     cell?.delegate = self
                   
                 return cell!
        }
        return UITableViewCell()
       }
    
   

   func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
       cellHeights[indexPath] = cell.frame.size.height
   }

   func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
       return cellHeights[indexPath] ?? UITableView.automaticDimension
   }
    override func btnDownTapped(cell: QuipCells) {
        //Get the indexpath of cell where button was tapped
        if let indexPath = self.feedTable.indexPath(for: cell){
       
            if let myQuip = newQuips[indexPath.row]{
            downButtonPressed(aQuip: myQuip, cell: cell)
                if let aQuipID = myQuip.quipID{
                myFeedController?.checkHotQuips(myQuipID: aQuipID, isUp: false)
                }

            }
        }
        
    }
    
    
    
    override func btnUpTapped(cell: QuipCells) {
           //Get the indexpath of cell where button was tapped
           if let indexPath = self.feedTable.indexPath(for: cell){
          
               if let myQuip = newQuips[indexPath.row]{
               upButtonPressed(aQuip: myQuip, cell: cell)
                if let aQuipID = myQuip.quipID{
                myFeedController?.checkHotQuips(myQuipID: aQuipID, isUp: true)
                }
               }
               
           
           }
       }
    
   override func btnSharedTapped(cell: QuipCells) {
                        if let indexPath = self.feedTable.indexPath(for: cell){
                                
                                     if let myQuip = newQuips[indexPath.row]{
                                    generateDynamicLink(aquip: myQuip, cell: cell)
                                     }
                                     
                                 
                                 }
                          
       }
    
    override func btnEllipsesTapped(cell: QuipCells) {
       
        if let indexPath = self.feedTable.indexPath(for: cell){
                                          
                                               if let myQuip = newQuips[indexPath.row]{
                                                if let myFeedController = myFeedController{
                                                MenuLauncher.setVars(feedController: myFeedController, myQuip: myQuip)
                                                }
                                               }
                                               
                                           
                                           }
         MenuLauncher.makeViewFade()
        MenuLauncher.addMenuFromBottom()
     
    }
    
   
      func scrollViewDidScroll(_ scrollView: UIScrollView) {
          let height = scrollView.frame.size.height
          let contentYoffset = scrollView.contentOffset.y
          let distanceFromBottom = scrollView.contentSize.height - contentYoffset
          if distanceFromBottom < height {
             
                     
                    
                         // handle your logic here to get more items, add it to dataSource and reload tableview
                       
                                 if moreRecentQuipsFirestore {
                                    loadMoreRecent()
                                 }
                                
                                 
                  
          }
      }
    
}


class CollectionViewCellFeedTop: CollectionCellFeed,UITableViewDelegate, UITableViewDataSource  {
   
    private var refreshControl=UIRefreshControl()
     private var myHotIDs:[String]=[]
    private var moreHotQuipsFirebase:Bool = false
    private var cellHeights = [IndexPath: CGFloat]()
    
    @IBOutlet weak var feedTable: UITableView!
    
    override func awakeFromNib() {
         super.awakeFromNib()
         feedTable.delegate = self
         feedTable.dataSource = self
       self.feedTable.rowHeight = UITableView.automaticDimension
             self.feedTable.estimatedRowHeight = 500.0
         refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        feedTable.refreshControl = refreshControl
      }
    
    @objc func refreshData(){
           
        updateHot(){
            
        }
       }
    
    func updateHot(completion: @escaping ()->()){
         refreshControl.beginRefreshing()
         self.hotQuips = []
         self.myHotIDs = []
         
         moreHotQuipsFirebase = false
         if let myChannelKey = myFeedController?.myChannel?.key{
             
             FirebaseService.sharedInstance.getHotFeed(myChannelKey: myChannelKey) {[weak self] (myHotQuips, myHotQuipIDs, moreHotQuipsFirebase, currentTime)  in
                 self?.hotQuips = myHotQuips
                 self?.myHotIDs = myHotQuipIDs
                 self?.currentTime = currentTime
                 FirestoreService.sharedInstance.getHotQuipsFeed(myChannelKey: myChannelKey, aHotIDs: myHotQuipIDs, hotQuips: myHotQuips) {[weak self] (myData, aHotQuips, more) in
                     self?.populateHotQuipsArr(data: myData, aHotQuips: aHotQuips, more: more)
                     self?.moreHotQuipsFirebase = moreHotQuipsFirebase
                     self?.refreshControl.endRefreshing()
                    completion()
                 }
             }
             
         }
         
     }
    
     
     func populateHotQuipsArr(data:[String:Any], aHotQuips:[Quip?], more:Bool){
              for aQuip in aHotQuips{
                  if let myQuip = aQuip{
                      if let myID = myQuip.quipID{
                          let quipData = data[myID] as! [String:Any]
                          myQuip.user = quipData["a"] as? String
                          myQuip.channel = quipData["c"] as? String
                          myQuip.channelKey = quipData["k"] as? String
                          myQuip.quipText = quipData["t"] as? String
                          myQuip.timePosted = quipData["d"] as? Timestamp
                         myQuip.gifID = quipData["g"] as? String
                         myQuip.imageRef = quipData["i"] as? String
                      
                  }
                  }
                  
              }
              if more{
                  self.hotQuips = self.hotQuips + aHotQuips
              }
              self.feedTable.reloadData()
              
              
          }
     
     
    
     
    
     
    
     func loadMoreHotQuips(){
         moreHotQuipsFirebase = false
         if let myChannelKey = myFeedController?.myChannel?.key{
             FirebaseService.sharedInstance.loadMoreHotFeed(myChannelKey: myChannelKey) {[weak self] (aHotQuips, aHotIDs, moreHotQuipsFirebase) in
                 FirestoreService.sharedInstance.loadMoreHotFeed(myChannelKey: myChannelKey, aHotIDs: aHotIDs, hotQuips: aHotQuips) {[weak self] (myData, aHotQuips, more) in
                     self?.populateHotQuipsArr(data: myData, aHotQuips: aHotQuips, more: more)
                     self?.moreHotQuipsFirebase = moreHotQuipsFirebase
                     self?.refreshControl.endRefreshing()
                 }
                 
                 
             }
         }
        
         
     }
    
    //gets number of sections for tableview
       func numberOfSections(in tableView: UITableView) -> Int {
           return 1
       }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hotQuips.count
       }
       
       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = feedTable.dequeueReusableCell(withIdentifier: "feedCell", for: indexPath) as? QuipCells {
            if hotQuips.count > 0 {
                               if let myQuip = self.hotQuips[indexPath.row]{
                                   cell.aQuip=myQuip
                               if let myImageRef = myQuip.imageRef {
                                   
                                       cell.addImageViewToTableCell()
                                       cell.myImageView.getImage(myQuipImageRef: myImageRef, feedTable: self.feedTable)
                                   
                                                                
                               }
                                                                                                   
                               else if let gifID = myQuip.gifID {
                                                             
                                       cell.addGifViewToTableCell()
                                       cell.myGifView.getImageFromGiphy(gifID: gifID, feedTable:self.feedTable)
                                                                                                       
                               }
                              
                               
                              
                               if let dateVal = myQuip.timePosted?.seconds{
                                   let milliTimePost = dateVal * 1000
                                   cell.timePosted.text = timeSincePost(timePosted: Double(milliTimePost), currentTime: self.currentTime!)
                               }
                                   if let aID = myQuip.quipID{
                               if self.myFeedController?.myLikesDislikesMap[aID] == 1{
                                           cell.upButton.isSelected=true
                                  
                                  
                                   cell.upButton.tintColor = UIColor(red: 152.0/255.0, green: 212.0/255.0, blue: 186.0/255.0, alpha: 1.0)
                               }
                               else if self.myFeedController?.myLikesDislikesMap[aID] == -1{
                                           cell.downButton.isSelected=true
                                                 cell.downButton.tintColor = UIColor(red: 152.0/255.0, green: 212.0/255.0, blue: 186.0/255.0, alpha: 1.0)
                               }
                               }
                               }
                                else{
                                        return cell
                                }
                
                            cell.downButton.changeButtonWeight()
                                 cell.upButton.changeButtonWeight()
                                 cell.delegate = self
                            
                             return cell
                        }
            
        }
          return UITableViewCell()
       }
    
   func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
         cellHeights[indexPath] = cell.frame.size.height
     }

     func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
         return cellHeights[indexPath] ?? UITableView.automaticDimension
     }
      override func btnDownTapped(cell: QuipCells) {
          //Get the indexpath of cell where button was tapped
          if let indexPath = self.feedTable.indexPath(for: cell){
         
              
              if let myQuip = hotQuips[indexPath.row]{
              downButtonPressed(aQuip: myQuip, cell: cell)
                if let aQuipID = myQuip.quipID{
                    myFeedController?.checkNewQuips(myQuipID: aQuipID, isUp: false)
                }
              }
          }
          
      }
    
    override func btnUpTapped(cell: QuipCells) {
           //Get the indexpath of cell where button was tapped
           if let indexPath = self.feedTable.indexPath(for: cell){
           
               if let myQuip = hotQuips[indexPath.row]{
               upButtonPressed(aQuip: myQuip, cell: cell)
                if let aQuipID = myQuip.quipID{
                    myFeedController?.checkNewQuips(myQuipID: aQuipID, isUp: true)
                }
               }
            
        }
       }
    
    override func btnSharedTapped(cell: QuipCells) {
                           if let indexPath = self.feedTable.indexPath(for: cell){
                                   
                                        if let myQuip = hotQuips[indexPath.row]{
                                       generateDynamicLink(aquip: myQuip, cell: cell)
                                        }
                                        
                                    
                                    }
                             
          }
    
    override func btnEllipsesTapped(cell: QuipCells) {
        
            
           if let indexPath = self.feedTable.indexPath(for: cell){
                                        
                                             if let myQuip = hotQuips[indexPath.row]{
                                                if let myFeedController = myFeedController{
                                               MenuLauncher.setVars(feedController: myFeedController, myQuip: myQuip)
                                                }
                                             }
                                             
                                         
                                         }
        MenuLauncher.makeViewFade()
        MenuLauncher.addMenuFromBottom()
 
       }
   
    
      func scrollViewDidScroll(_ scrollView: UIScrollView) {
          let height = scrollView.frame.size.height
          let contentYoffset = scrollView.contentOffset.y
          let distanceFromBottom = scrollView.contentSize.height - contentYoffset
          if distanceFromBottom < height {
             
                     
                    
                         // handle your logic here to get more items, add it to dataSource and reload tableview
                        
                                     if moreHotQuipsFirebase {
                                      loadMoreHotQuips()
                                      }
                                
                  
          }
      }
}
